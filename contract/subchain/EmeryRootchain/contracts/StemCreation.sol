pragma solidity ^0.4.24;

// external modules
import "./ByteUtils.sol";
import "./ECRecovery.sol";
import "./Merkle.sol";
import "./PriorityQueue.sol";
import "./RLP.sol";
import "./RLPEncoding.sol";
import "./SafeMath.sol";
import "./StemCore.sol";
import "./StemChallenge.sol";

library StemCreation {
    using RLP for bytes;
    using RLP for RLP.RLPItem;
    using RLPEncoding for address;
    using RLPEncoding for uint256;
    using RLPEncoding for bytes[];
    using PriorityQueue for uint256[];
    using SafeMath for uint256;

    function createSubchain(StemCore.ChainStorage storage self, uint256 _msgValue, address _msgSender, bytes32 _subchainName, bytes32 _genesisBalanceTreeRoot, bytes32 _genesisTxTreeRoot, bytes32[] _staticNodes, uint256 _creatorDeposit, address[] _ops, uint256[] _opsDeposits) public {
        StemCore.init(self);
        require(_ops.length >= self.MIN_LENGTH_OPERATOR && _ops.length <= self.MAX_LENGTH_OPERATOR, "Invalid operators length");
        require(_ops.length == _opsDeposits.length, "Invalid deposits length");
        require(_creatorDeposit >= self.creatorMinDeposit, "Insufficient creator deposit value");

        // Setup the operators' deposits and initial fees
        self.totalDeposit = _creatorDeposit;
        for (uint256 i = 0; i < _ops.length && StemCore.isValidAddOperator(self, _ops[i], _opsDeposits[i]); i++){
            require(self.isExistedOperators[_ops[i]] == false, "Repeated operator");
            self.operators[_ops[i]] = _opsDeposits[i];
            self.operatorFee[_ops[i]] = 0;
            self.totalDeposit = self.totalDeposit.add(_opsDeposits[i]);
            self.isExistedOperators[_ops[i]] = true;
            self.operatorIndices.push(_ops[i]);
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
            balanceTreeRoot: _genesisBalanceTreeRoot,
            txTreeRoot: _genesisTxTreeRoot,
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
}