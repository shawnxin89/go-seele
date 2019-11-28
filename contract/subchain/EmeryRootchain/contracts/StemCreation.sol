pragma solidity ^0.4.24;

// external modules
import "./SafeMath.sol";
import "./StemCore.sol";
import "./StemRelay.sol";

// This library includes the construtor of a Stem contract
library StemCreation {
    using SafeMath for uint256;

     /**
     * @dev The rootchain constructor creates the rootchain
     * contract, initializing the owner and operators
     * @param _subchainName The name of the subchain
     * @param _genesisInfo [balanceTreeRoot, TxTreeRoot]
     *        The hash of the genesis balance tree root
     *        The hash of the genesis tx tree root
     * @param _staticNodes The static nodes
     * @param _creatorDeposit The deposit of creator
     * @param _ops The operators.
     * @param _opsDeposits The deposits of operators.
     * @param _refundAccounts The mainnet addresses of the operators
     */
    function createSubchain(StemCore.ChainStorage storage self, bytes32 _subchainName, bytes32[] _genesisInfo, bytes32[] _staticNodes, uint256 _creatorDeposit, address[] _ops, uint256[] _opsDeposits, address[]  _refundAccounts, address _msgSender, uint256 _msgValue) public {
        // initialize the storage variables
        init(self);
        require(_ops.length >= self.MIN_LENGTH_OPERATOR && _ops.length <= self.MAX_LENGTH_OPERATOR, "Invalid operators length");
        require(_ops.length == _opsDeposits.length, "Invalid deposits length");
        require(_ops.length == _refundAccounts.length, "Invalid length of refund accounts");
        require(_creatorDeposit >= self.creatorMinDeposit, "Insufficient creator deposit value");
        require(_genesisInfo.length == 2, "Invalid length of genesis info");
        // Setup the operators' deposits and initial fees
        self.totalDeposit = _creatorDeposit;
        for (uint256 i = 0; i < _ops.length && StemCore.isValidAddOperator(self, _ops[i], _opsDeposits[i]); i++){
            require(self.isExistedOperators[_ops[i]] == false, "Repeated operator");
            self.operators[_ops[i]] = _opsDeposits[i];
            self.operatorFee[_ops[i]] = 0;
            self.totalDeposit = self.totalDeposit.add(_opsDeposits[i]);
            self.isExistedOperators[_ops[i]] = true;
            self.operatorIndices.push(_ops[i]);
            self.refundAddress[_ops[i]] = _refundAccounts[i];
        }
        require(_msgValue >= self.totalDeposit, "You don't give me enough money");
        self.owner = _msgSender;
        self.creatorDeposit = _creatorDeposit;

        // Register subchain info
        self.subchainName = _subchainName;
        self.staticNodes = _staticNodes;
        uint256 submittedBlockNumber = 0;
        //Create the genesis block.
        self.childBlocks[submittedBlockNumber] = StemCore.ChildBlock({
            submitter: _msgSender,
            balanceTreeRoot: _genesisInfo[0],
            txTreeRoot: _genesisInfo[1],
            timestamp: block.timestamp
        });

        // update child block number/deposit block number/exit block number
        self.nextChildBlockNum = 0;
        self.nextChildBlockNum = self.nextChildBlockNum.add(self.CHILD_BLOCK_INTERVAL);
        self.nextDepositBlockIncrement = 1;
        self.curDepositBlockNum = self.nextChildBlockNum.add(self.nextDepositBlockIncrement);
        self.nextExitBlockIncrement = 1;
        self.curExitBlockNum = self.nextChildBlockNum.add(self.nextExitBlockIncrement);
        // By default, all the initial operators' deposit should be processed on the subchain at genesis block. (The genesis block height is 0)
    }

     /**
    * @dev Initialize the contract parameters
     */
    function init(StemCore.ChainStorage storage self) internal {
        self.MIN_LENGTH_OPERATOR = 1;
        self.MAX_LENGTH_OPERATOR = 100;
        self.CHILD_BLOCK_INTERVAL = 1000;
        self.IS_NEW_OPERATOR_ALLOWED = true;
        self.creatorMinDeposit = 1000;
        self.childBlockChallengePeriod = 0 seconds;//1 days;
        self.childBlockChallengeSubmissionPeriod = 0 seconds;//12 hours;
        self.isBlockSubmissionBondReleased = true;
        self.blockSubmissionBond = 1234567890;
        self.blockChallengeBond = 1234567890;
        self.operatorMinDeposit = 1234567890;
        self.operatorExitBond = 1234567890;
        self.userMinDeposit = 1234567890;
        self.userExitBond = 1234567890;
        self.isFrozen = false;
    }

    /**
    * @dev Discard the subchain
     */
    function discardSubchain(StemCore.ChainStorage storage self, address _msgSender) public {
        require(self.isFrozen == false, "The subchain is frozen");
        //require(_msgSender == self.owner, "msg.sender must be the subchain owner");
        self.isFrozen = true;
        if (StemCore.isLastChildBlockConfirmed(self) == false) {
            StemRelay.doReverseBlock(self, self.lastChildBlockNum);
        }
        // return owner's deposit
        self.owner.transfer(self.creatorDeposit);
        address acc;
        // return users' deposit
        for (uint i = 0; i < self.userIndices.length; i++) {
            acc = self.userIndices[i];
            self.refundAddress[acc].transfer(self.users[acc]);
        }
        // return operators' deposit
        for (i = 0; i < self.operatorIndices.length; i++) {
            acc = self.operatorIndices[i];
            self.refundAddress[acc].transfer(self.operators[acc]);
        }
        // return the deposits in the deposit requests
        for (i = 0; i < self.depositsIndices.length; i++) {
            acc = self.depositsIndices[i];
            if (self.deposits[acc].blkNum > self.lastChildBlockNum) {
                self.deposits[acc].refundAccount.transfer(self.deposits[acc].amount);
            }
        }

        // return all the exit bonds
        for (i = 0; i < self.exitsIndices.length; i++) {
            acc = self.exitsIndices[i];
            if (self.exits[acc].executed == false) {
                self.refundAddress[acc].transfer(self.exits[acc].amount);
            }
        }

        // return blockSubmissionBond
        if (!self.isBlockSubmissionBondReleased)
        {
            self.childBlocks[self.lastChildBlockNum].submitter.transfer(self.blockSubmissionBond);
            self.isBlockSubmissionBondReleased = true;
        }
    }
}