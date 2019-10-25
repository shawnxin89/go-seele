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
    address   public owner;
    bytes32   public subchainName;
    bytes32[] public staticNodes;
    uint256   public creatorDeposit;
    uint256   public creatorMinDeposit = 1000;

    /** @dev subchain related */
    uint256 public nextDepositBlock;
    uint256 public nextChildBlockNum;
    struct ChildBlock{
        address submitter;
        bytes32 balanceTreeRoot;
        bytes32 txTreeRoot;
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
    mapping(address => bool) public isExistedOperators;
    uint128 public operatorMinDeposit = 1234567890;

    /** @dev User related */
    uint256 public userslen;
    mapping(address => uint256) public users;
    mapping(address => bool) public isExistedUsers;
    uint256 public userMinDeposit = 1234567890;
    uint256 public userExitBond = 1234567890;
    /*uint256 public exitNonce = 0;
    uint256 public exitTimeLimit = 1 weeks;
    uint256[] public userExitQueue;
    mapping(uint256 => Exit) public userExits;
    struct Exit{
        address user;
        uint256 deposit;
        uint256 bond;
        uint256 timestamp;
    } */

    /** events */
    event AddOperator(
        address indexed operator,
        uint256 indexed blkNum,
        uint256 deposit
    );
    event UserDeposit(
        address indexed user,
        uint256 indexed blkNum,
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
     * @dev The rootchain constructor creates the rootchain
     * contract and initialize the owner and operators.
     * @param _subchainName Is the name of the subchain
     * @param _genesisBalanceTreeRoot Is the hash of the genesis balance tree root
     * @param _genesisTxTreeRoot Is the hash of the genesis tx tree root
     * @param _staticNodes Is the static nodes
     * @param _creatorDeposit Is the deposit of creator
     * @param _ops Is the operators.
     * @param _opsDeposits Is the deposits of operators.
     */
    constructor(bytes32 _subchainName, bytes32 _genesisBalanceTreeRoot, bytes32 _genesisTxTreeRoot, bytes32[] _staticNodes, uint256 _creatorDeposit, address[] _ops, uint256[] _opsDeposits)
    public payable {
        require(_ops.length >= MIN_LENGTH_OPERATOR && _ops.length <= MAX_LENGTH_OPERATOR, "Invalid operators length");
        require(_ops.length == _opsDeposits.length, "Invalid deposits length");

        // Handle the deposits
        uint256 amount = 0;
        require(_creatorDeposit >= creatorMinDeposit, "Insufficient creator deposit value");
        amount = amount.add(_creatorDeposit);
        for (uint256 i = 0; i < _ops.length && isValidAddOperator(_ops[i], _opsDeposits[i]); i++){
            require(operators[_ops[i]] == 0, "Repeated operator");
            operators[_ops[i]] = _opsDeposits[i];
            amount = amount.add(_opsDeposits[i]);
            isExistedOperators[_ops[i]] = true;
        }
        require(msg.value >= amount, "You don't give me enough money");
        owner = msg.sender;
        opslen = _ops.length;
        creatorDeposit = _creatorDeposit;

        // Register subchain info
        subchainName = _subchainName;
        staticNodes = _staticNodes;
        uint256 submittedBlockNumber = 0;
        //Create the genesis block.
        childBlocks[submittedBlockNumber] = ChildBlock({
            submitter: msg.sender,
            balanceTreeRoot: _genesisBalanceTreeRoot,
            txTreeRoot: _genesisTxTreeRoot,
            timestamp: block.timestamp
        });

        nextChildBlockNum = 0;
        nextChildBlockNum = nextChildBlockNum.add(CHILD_BLOCK_INTERVAL);
        nextDepositBlock = 1;
        userslen = 0;
        // By default, all the initial operators' deposit should be processed on the subchain at block height 1. (The genesis block height is 0)
    }

    /**
    * @dev New operator join the subchain
    * @param _operator Is the operator of the subchain
    */
    function addOperator(address _operator) public payable {
        require(IS_NEW_OPERATOR_ALLOWED, "Adding new operator is not allowed");
        require(isExistedOperators[_operator] == false, "Repeated operator");
        require(isExistedUsers[_operator] == false, "This address has been registered as a user");
        require(isValidAddOperator(_operator, msg.value), "Unable to add this operator");
        require(opslen <= MAX_LENGTH_OPERATOR, "Reach the maximum number of operators");

        uint256 blkNum = _processDepositBlockNum();

        operators[_operator] = msg.value;
        isExistedOperators[_operator] = true;
        opslen = opslen.add(1);
        emit AddOperator(
            _operator,
            blkNum,
            msg.value
        );
    }

    /**
     * @dev Verify that the operator is valid and that the deposit is sufficient
     * @param _operator Is the operator of the subchain
     * @param _deposit Is the deposit of the operator.
     * return true if the operator is valid
     */
    function isValidAddOperator(address _operator, uint256 _deposit) public view returns(bool){
        require(_operator != address(0), "Invalid operator address");
        require(_deposit >= operatorMinDeposit, "Insufficient operator deposit value");

        return true;
    }

    /**
    * @dev Allow user deposit to the subchain
    * @param _user Is the user of the subchain
    */
    /*function userDeposit(address _user) public payable {
        require(isValidUserDeposit(_user, msg.value), "Unable to deposit for this user");

        uint256 blkNum = _processDepositBlockNum();

        if (users[_user] > 0) {
            // this user already exists
            users[_user] = users[_user].add(msg.value);
        } else {
            users[_user] = msg.value;
            isExistedUsers[_user] = true;
            userslen = userslen.add(1);
        }

        emit UserDeposit(
            _user,
            blkNum,
            msg.value
        );
    } */

    /**
    * @dev Verify that the user is valid and that the deposit is sufficient
    * @param _user Is the user of the subchain
    * @param _deposit Is the deposit of the user.
    * return true if the user is valid
    */
    /*function isValidUserDeposit(address _user, uint256 _deposit) public view returns(bool){
        require(_user != address(0), "Invalid user address");
        require(_deposit >= userMinDeposit, "Insufficient user deposit value");

        return true;
    }*/

    /**
    * @dev process next deposit block number
    * return next deposit block number
    */
    function _processDepositBlockNum() internal returns(uint256) {
        // Only allow a limited number of deposits per child block. 1 <= nextDepositBlock < CHILD_BLOCK_INTERVAL.
        require(nextDepositBlock < CHILD_BLOCK_INTERVAL, "Too many deposit blocks");
        // get next deposit block number.
        uint256 blknum = getDepositBlockNumber();
        nextDepositBlock++;

        return blknum;
    }

    /**
    * @dev Calculates the next deposit block.
    * @return Next deposit block number.
    */
    function getDepositBlockNumber() public view returns (uint256)
    {
        return nextChildBlockNum.add(nextDepositBlock);
    }

    /**
    * @dev Get child block's hash
    * TODO: root hash of balance tree and root hash of recent tx tree
    * @param _blockNum Is the submitted block number
    * return the hash of child block
    */
    /*function getChildBlockHash(uint256 _blockNum) public view returns(bytes32) {
       return childBlocks[_blockNum].root;
    }

    /**
    * @dev Get child block's hash
    * @param _blockNum Is the submitted block number
    */
    function getChildBlockTimestamp(uint256 _blockNum) public view returns(uint256) {
       return childBlocks[_blockNum].timestamp;
    }

     /**
     * @dev Allows the operator to submit a child block.
     * @param _balanceTreeRoot Is the root of the balance tree of the subchain.
     * @param _txTreeRoot Is the root of recent tx tree of the subchain.
     * @param _accounts Is the accounts to be updated
     * @param _updatedBalances Is the updated balance of the accounts
     */
    /*function submitBlock(bytes32 _balanceTreeRoot, bytes32 _txTreeRoot, address[] _accounts, uint256[] _updatedBalances) public payable onlyOperator onlyWithValue(blockSubmissionBond) {
        // make sure last submitted child block is confirmed and release last block submitter's bond
        uint256 lastBlkNum = getLastChildBlockNumber();
        require(block.timestamp.sub(childBlocks[lastBlkNum].timestamp) > childBlockChallengePeriod, "Last submitted block is in challenge period");
        // check existing challenges
        if (childBlockChallengeId.length > 0) {
            delete childBlocks[lastBlkNum];
            nextChildBlockNum = lastBlkNum;
            // reverse the balances updated by last submitted child block
            for (uint i = 0; i < opAccountsBackup.length; i++) {
                operators[opAccountsBackup[i]] = opBalancesBackup[i];
            }
            delete opAccountsBackup;
            delete opBalancesBackup;
            for (uint i = 0; i < userAccountsBackup.length; i++) {
                users[userAccountsBackup[i]] = userBalancesBackup[i];
            }
            delete userAccountsBackup;
            delete userBalancesBackup;

            // TODO: clear the exit requests

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
                childBlocks[lastBlkNum].submitter.transfer(blockSubmissionBond);
            }

            // operator bond is locked
            isBlockSubmissionBondReleased = false;

            // Create the block.
            childBlocks[nextChildBlockNum] = ChildBlock({
                submitter: msg.sender,
                balanceTreeRoot: _balanceTreeRoot,
                txTreeRoot: _txTreeRoot,
                timestamp: block.timestamp
            });

            // backup and update some accounts


            // Update the next child and deposit blocks.
            nextChildBlockNum = nextChildBlockNum.add(CHILD_BLOCK_INTERVAL);
            nextDepositBlock = 1;

            emit BlockSubmitted(nextChildBlockNum);
        }
    } */

    /**
    * @dev Allows a challenge to the submitted block.
    * @param _challengeTarget The target account to challenge
    */
    /*function challengeSubmittedBlock(address _challengeTarget) public payable onlyWithValue(blockChallengeBond) {
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
    } */

    /**
    * @dev get an ID for the input block challenge
    * @param challengerAddress Is the challenger's address
    * @param challengeTarget Is the target account to challenge
    * @param blkNum Is the child block number to challenge
    * @return the id of the input block challenge
    */
    /*function _getBlockChallengeId(address challengerAddress, address challengeTarget, uint256 blkNum) public view returns (bytes) {
       return _computeId(keccak256(abi.encodePacked(challengerAddress, challengeTarget)), blkNum);
    } */

    /**
    * @dev get Id for the input info
    */
    /*function _computeId(bytes32 infoHash, uint256 pos) internal returns (uint192)
    {
        return uint192((uint256(infoHash) >> 105) | (pos << 152));
    }*/

    /**
    * @dev Allows an operator to submit a proof in response to a block challenge.
    * @param challengeIndex Is the index of the challenge
    * @param _blockChallengeProof Is a proof in response to a block challenge
    */
    /*function responseToBlockChallenge(uint challengeIndex, bytes _blockChallengeProof) public onlyOperator {
        require(childBlockChallengeId.length > challengeIndex, "Invalid challenge index");
        // validate the response to the block challenge
        bool flag = _processResponseToBlockChallenge(challengeIndex, _blockChallengeProof);
        if (flag) {
            // respond to the block challenge successfully
            msg.sender.transfer(blockChallengeBond);
            _removeChildBlockChallengeByIndex(challengeIndex);
        }
    } */

    /** TODO */
    // _processResponseToBlockChallenge


    /**
    * @dev remove child block challenge by its index
    * @param index Is the index of the challenge
    */
    /*function _removeChildBlockChallengeByIndex(uint index) internal {
        if (index >= childBlockChallengeId.length) return;

        delete childBlockChallenges[childBlockChallengeId[index]];
        for (uint i = index; i < childBlockChallengeId.length - 1; i++){
            childBlockChallengeId[i] = childBlockChallengeId[i + 1];
        }
        delete childBlockChallengeId[childBlockChallengeId.length - 1];
        childBlockChallengeId.length--;
    } */

    /**
    * @dev clear existing child block challenges
    */
    /* function _clearExistingBlockChallenges() internal {
        for (uint i = 0; i < childBlockChallengeId.length; i++) {
            // return challenge bond to the challengers
            childBlockChallenges[childBlockChallengeId[i]].challengerAddress.transfer(blockChallengeBond);
            delete childBlockChallenges[childBlockChallengeId[i]];
        }
        delete childBlockChallengeId;
    } */

    /**
    * @dev Calculates the last submitted child block num.
    * @return Last submitted child block number.
    */
    /* function getLastChildBlockNumber() public view returns (uint256)
    {
        return nextChildBlockNum.sub(CHILD_BLOCK_INTERVAL);
    } */
}