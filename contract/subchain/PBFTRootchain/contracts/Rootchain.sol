pragma solidity ^0.4.24;

// external modules
import "./ByteUtils.sol";
import "./ECRecovery.sol";
import "./SafeMath.sol";
import "./PriorityQueue.sol";

/// @title A multiple-operator subchain contract in Seele root chain
/// @notice You can use this contract for a multiple-operator subchain in Seele.
/// @author seeledev

contract MultipleOperatorRootchain {
    using SafeMath for uint256;
    using PriorityQueue for uint256[];

    uint8 constant public MIN_LENGTH_OPERATOR = 1;
    uint8 constant public MAX_LENGTH_OPERATOR = 100;
    uint256 constant public CHILD_BLOCK_INTERVAL = 1000;
    bool  constant public IS_NEW_OPERATOR_ALLOWED = true;

    /** @dev subchain info */
    address   private owner;
    bytes32   public subchainName;
    bytes32[] public staticNodes;
    uint256   public creatorDeposit;
    uint256   public creatorMinDeposit;

    /** @dev subchain related */
    uint256 public nextChildBlockNum;
    struct ChildBlock{
        bytes32 root;
        uint256 timestamp;
    }
    mapping(uint256 => ChildBlock) public childBlocks;

    uint256 public childBlockChallengePeriod = 1 days;
    uint256 public childBlockChallengeSubmissionPeriod = 12 hours;
    bool    public isBlockSubmissionBondReleased = true;
    uint256 public blockSubmissionBond = 1234567890;
    uint256 public blockChallengeBond = 1234567890;
    struct ChildBlockChallenge{
        address challengerAddress;
        address challengeTarget;
    }
    uint192[] childBlockChallengeId;
    mapping(uint192 => ChildBlockChallenge) public childBlockChallenges;

    /** @dev Operator related */
    uint256 public opslen;
    mapping(address => uint256) public operators;
    uint128 public operatorMinDeposit = 1234567890;

    /** @dev User related */
    mapping(address => uint256) public users;
    uint256 public userMinDeposit = 1234567890;
    uint256 public userExitBond = 1234567890;
    uint256 public exitNonce = 0;
    uint256 public exitTimeLimit = 1 weeks;
    uint256[] public userExitQueue;
    mapping(uint256 => Exit) public userExits;
    struct Exit{
        address user;
        uint256 deposit;
        uint256 bond;
        uint256 timestamp;
    }

    /** events */
    event AddOperator(address indexed operator);
    event UserDeposit(address indexed user);
    event DepositCreated(
        uint256 indexed blknum,
        address indexed depositor,
        uint256 deposit
    );
    event BlockSubmitted(
        uint256 blockNumber
    );

    /** @dev Reverts if called by any account other than the owner. */
    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner of the contract");
         _;
    }

    /** @dev Reverts if called by any account other than the operator. */
    modifier onlyOperator() {
        require(operators[msg.sender] > 0, "You're not the operator of the contract");
        _;
    }

    /** @dev Reverts if the message value does not equal to the desired value */
    modifier onlyWithValue(uint256 _value) {
        require(msg.value == _value, "Incorrect amount of input!");
        _;
    }

    /**
     * @dev The Rootchain constructor sets the original `owner` of the
     * contract to the sender account and initialize the operators.
     * @param _subchainName Is the name of the subchain
     * @param _genesisHash Is the hash of the genesis
     * @param _staticNodes Is the static nodes
     * @param _creatorDeposit Is the deposit of creator
     * @param ops Is the operators.
     * @param opsDeposits Is the deposits of operators.
     */
    constructor(
        bytes32 _subchainName,
        bytes32 _genesisHash,
        bytes32[] _staticNodes,
        uint256 _creatorDeposit,
        address[] ops,
        uint256[] opsDeposits
    )
    public payable {
        require(ops.length >= MIN_LENGTH_OPERATOR && ops.length <= MAX_LENGTH_OPERATOR, "Invalid operators length");
        require(ops.length == opsDeposits.length, "Invalid deposits length");

        // Handle the deposits
        uint256 amount = 0;
        require(_creatorDeposit >= creatorMinDeposit, "Insufficient creator deposit value");
        amount = amount.add(_creatorDeposit);
        for (uint256 i = 0; i < ops.length && isValidAddOperator(ops[i], opsDeposits[i]); i++){
            require(operators[ops[i]] == 0, "Repeated operator");
            operators[ops[i]] = opsDeposits[i];
            amount = amount.add(opsDeposits[i]);
        }
        require(msg.value >= amount, "You don't give me enough money");
        owner = msg.sender;
        opslen = ops.length;
        creatorDeposit = _creatorDeposit;

        // Register subchain info
        subchainName = _subchainName;
        staticNodes = _staticNodes;
        uint256 submittedBlockNumber = 0;
        // Create the genesis block.
        childBlocks[submittedBlockNumber] = ChildBlock({
            root: _genesisHash,
            timestamp: block.timestamp
        });

        nextChildBlockNum = 0;
        nextChildBlockNum.add(CHILD_BLOCK_INTERVAL);
        // By default, all the initial operators' deposit should be processed on the subchain at block height 1. (The genesis block height is 0)
    }

    /**
     * @dev Verify that the operator is valid and that the deposit is sufficient
     * @param operator Is the operator of the subchain
     * @param deposit Is the deposit of the operator.
     */
    function isValidAddOperator(address operator, uint256 deposit) public view returns(bool){
        require(operator != address(0), "Invalid operator address");
        require(deposit >= operatorMinDeposit, "Insufficient operator deposit value");

        return true;
    }

    /**
    * @dev New operator join the subchain
    * @param operator Is the operator of the subchain
    */
    function addOperator(address operator) public payable {
        require(IS_NEW_OPERATOR_ALLOWED, "Adding new operator is not allowed");
        require(operators[operator] == 0, "Repeated operator");
        require(isValidAddOperator(operator, msg.value), "Unable to add this operator");
        require(opslen >= MAX_LENGTH_OPERATOR, "Reach the maximum number of operators");

        _processDeposit(operator, msg.value);

        operators[operator] = msg.value;
        opslen = opslen.add(1);
        emit AddOperator(operator);
    }

    /**
    * @dev Allow user put deposits in the subchain
    * @param user Is the user of the subchain
    * @param deposit Is the deposit of the user.
    */
    function userDeposit(address user) public payable {
        require(isValidUserDeposit(user, msg.value), "Unable to deposit for this user");

        _processDeposit(user, msg.value);

        if (users[user] > 0) {
            // this user already exists
            users[user] = users[user].add(msg.value);
        } else {
            users[user] = msg.value;
        }

        emit UserDeposit(user);
    }

    /**
    * @dev Verify that the user is valid and that the deposit is sufficient
    * @param user Is the user of the subchain
    * @param deposit Is the deposit of the user.
    */
    function isValidUserDeposit(address user, uint256 deposit) public view returns(bool){
        require(user != address(0), "Invalid user address");
        require(deposit >= userMinDeposit, "Insufficient user deposit value");

        return true;
    }

    /**
    * @dev record the deposit
    * @param depositor May be an operator or normal user
    * @param deposit Is the deposit amount
    */
    function _processDeposit(address depositor, uint256 deposit) internal {
        // Only allow a limited number of deposits per child block.
        require(nextDepositBlock < CHILD_BLOCK_INTERVAL, "Too many deposit blocks");
        // Insert the deposit block.
        uint256 blknum = getDepositBlockNumber();

        emit DepositCreated(
            blknum,
            depositor,
            deposit
        );

        nextDepositBlock++;
    }

    /**
    * @dev Calculates the next deposit block.
    * @return Next deposit block number.
    */
    function getDepositBlockNumber() public view returns (uint256)
    {
        return nextChildBlockNum.sub(CHILD_BLOCK_INTERVAL).add(nextDepositBlock);
    }

     /**
     * @dev Allows the operator to submit a child block.
     * @param _blockRoot Merkle root of the block.
     */
    function submitBlock(bytes32 _blockRoot) public payable onlyOperator onlyWithValue(blockSubmissionBond) {
        // make sure last submitted child block is confirmed and release last block submitter's bond
        uint256 lastBlkNum = getLastChildBlockNumber();
        require(block.timestamp.sub(childBlocks[lastBlkNum].timestamp) > childBlockChallengePeriod, "Last submitted block in challenge period");
        // check existing challenges
        if (childBlockChallengeId.length > 0) {
            delete childBlocks[lastBlkNum];
            nextChildBlockNum = lastBlkNum;
            // only the first challenger gets the blockSubmissionBond
            if (!isBlockSubmissionBondReleased)
            {
                childBlockChallenges[childBlockChallengeId[0]].challengerAddress.transfer(blockSubmissionBond);
                isBlockSubmissionBondReleased = true;
            }
            // clear challenges
            _clearExistingBlockChallenges();
        } else {
            // no existing challenges
            if (!isBlockSubmissionBondReleased)
            {
                lastBlockSubmitter.transfer(blockSubmissionBond);
                isBlockSubmissionBondReleased = true;
            }

            // operator bond
            lastBlockSubmitter = msg.sender;
            isBlockSubmissionBondReleased = false;

            // Create the block.
            childBlocks[nextChildBlockNum] = Block({
                root: _blockRoot,
                timestamp: block.timestamp
            });

            // Update the next child and deposit blocks.
            nextChildBlockNum = nextChildBlockNum.add(CHILD_BLOCK_INTERVAL);
            nextDepositBlock = 1;

            emit BlockSubmitted(submittedBlockNumber);
        }
    }

    /**
    * @dev Allows a challenge to the submitted block.
    * @param _challengeTarget The target account to challenge
    */
    function challengeSubmittedBlock(address _challengeTarget) public payable onlyWithValue(blockChallengeBond) {
        // make sure it is within challenge submission period
        uint256 memory lastBlkNum = getLastChildBlockNumber();
        require(block.timestamp.sub(childBlocks[lastBlkNum].timestamp) <= childBlockChallengeSubmissionPeriod, "Not in challenge submission period");

        // Challenge target must exists.
        require(users[_challengeTarget] > 0, "The challenge target doesn't exist!");

        Challenge memory newChallenge = Challenge({
            challengerAddress: msg.sender,
            challengeTarget: _challengeTarget
        });
        uint256 challengeId = _getBlockChallengeId(challengerAddress, challengeTarget, lastBlkNum);
        childBlockChallenges[challengeId] = newChallenge;
        childBlockChallengeId.push(challengeId);
    }

    /**
    * @dev get an ID for the input block challenge
    * @param challengerAddress Is the challenger's address
    * @param challengeTarget Is the target account to challenge
    * @param blkNum Is the child block number to challenge
    * @return the id of the input block challenge
    */
    function _getBlockChallengeId(address challengerAddress, address challengeTarget, uint256 blkNum) public view returns (bytes) {
       return _computeId(keccak256(abi.encodePacked(challengerAddress, challengeTarget)), blkNum);
    }

    /**
    * @dev get Id for the input info
    */
    function _computeId(bytes32 infoHash, uint256 pos) internal returns (uint192)
    {
        return uint192((uint256(infoHash) >> 105) | (pos << 152));
    }

    /**
    * @dev Allows an operator to submit a proof in response to a block challenge.
    * @param challengeIndex Is the index of the challenge
    * @param _blockChallengeProof Is a proof in response to a block challenge
    */
    function responseToBlockChallenge(uint challengeIndex, bytes _blockChallengeProof) public onlyOperator {
        require(childBlockChallengeId.length > challengeIndex, "Invalid challenge index");
        // validate the response to the block challenge
        bool flag = _processResponseToBlockChallenge(challengeIndex, _blockChallengeProof);
        if (flag) {
            // respond to the block challenge successfully
            msg.sender.transfer(blockChallengeBond);
            _removeChildBlockChallengeByIndex(challengeIndex);
        }
    }

    /** TODO */
    // _processResponseToBlockChallenge


    /**
    * @dev remove child block challenge by its index
    * @param index Is the index of the challenge
    */
    function _removeChildBlockChallengeByIndex(uint index) internal {
        if (index >= childBlockChallengeId.length) return;

        delete childBlockChallenges[childBlockChallengeId[index]];
        for (uint i = index; i < childBlockChallengeId.length - 1; i++){
            childBlockChallengeId[i] = childBlockChallengeId[i + 1];
        }
        delete childBlockChallengeId[childBlockChallengeId.length - 1];
        childBlockChallengeId.length--;
    }

    /**
    * @dev clear existing child block challenges
    */
    function _clearExistingBlockChallenges() internal {
        for (uint i = 0; i < childBlockChallengeId.length; i++) {
            delete childBlockChallenges[childBlockChallengeId[i]];
        }
        delete childBlockChallengeId;
    }

    /**
    * @dev Calculates the last submitted child block.
    * @return Last submitted child block number.
    */
    function getLastChildBlockNumber() public view returns (uint256)
    {
        return nextChildBlockNum.sub(CHILD_BLOCK_INTERVAL);
    }
}