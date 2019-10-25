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

library StemChallenge {
    using RLP for bytes;
    using RLP for RLP.RLPItem;
    using RLPEncoding for address;
    using RLPEncoding for uint256;
    using RLPEncoding for bytes[];
    using PriorityQueue for uint256[];
    using SafeMath for uint256;

    function processChallenge(StemCore.ChainStorage storage self, address _challengeTarget, bytes _inspecBlock, bytes _inspecBlockSignature, bytes32 _inspecTxHash, uint256 _inspecTxIndex, bytes _txInclusionProof, bytes _inspecState, uint256 _inspecStateIndex, bytes _stateInclusionProof) 
    public {
        // make sure it is within challenge submission period
        require(block.timestamp.sub(self.childBlocks[self.lastChildBlockNum].timestamp) <= self.childBlockChallengeSubmissionPeriod, "Not in challenge submission period");

        // Challenge target must exist.
        require(self.isExistedUsers[_challengeTarget] || self.isExistedOperators[_challengeTarget], "The challenge target doesn't exist!");

        // decode _inspecBlock
        StemCore.InspecBlock memory decodedBlock = StemCore.decode(_inspecBlock);
        require(self.isExistedOperators[decodedBlock.creator], "The block is not created by existing operators");
        require(decodedBlock.creator == ECRecovery.recover(keccak256(_inspecBlock), _inspecBlockSignature), "Invalid signature");
        require(Merkle.checkMembership(_inspecTxHash, _inspecTxIndex, decodedBlock.txTreeRoot, _txInclusionProof), "Failed to prove the inclusion of the tx");
        // get the hash of the state
        require(Merkle.checkMembership(keccak256(_inspecState), _inspecStateIndex, decodedBlock.balanceTreeRoot, _stateInclusionProof), "Failed to prove the inclusion of the state");
        //TODO consider the case that _inspecTxHash is nil
        createChildBlockChallenge(self, msg.sender, _challengeTarget, _inspecTxHash, _inspecState);
    }

    function createChildBlockChallenge(StemCore.ChainStorage storage self, address _challengerAddress, address _challengeTarget, bytes32 _inspecTxHash, bytes _inspecState) internal {
        StemCore.ChildBlockChallenge memory newChallenge = StemCore.ChildBlockChallenge({
            challengerAddress: _challengerAddress,
            challengeTarget: _challengeTarget,
            inspecTxHash: _inspecTxHash,
            inspecState: _inspecState
        });
        uint192 challengeId = getBlockChallengeId(_challengerAddress, _challengeTarget, self.lastChildBlockNum);
        self.childBlockChallenges[challengeId] = newChallenge;
        self.childBlockChallengeId.push(challengeId);
    }

   /**
    * @dev Clear existing child block challenges
    */
    function clearExistingBlockChallenges(StemCore.ChainStorage storage self) internal {
        for (uint i = 0; i < self.childBlockChallengeId.length; i++) {
            // return challenge bond to the challengers
            self.childBlockChallenges[self.childBlockChallengeId[i]].challengerAddress.transfer(self.blockChallengeBond);
            delete self.childBlockChallenges[self.childBlockChallengeId[i]];
        }
        delete self.childBlockChallengeId;
    }

     /**
    * @dev get an ID for the input block challenge
    * @param _challengerAddress Is the challenger's address
    * @param _challengeTarget Is the target account to challenge
    * @param _blkNum Is the child block number to challenge
    * @return the id of the input block challenge
    */
    function getBlockChallengeId(address _challengerAddress, address _challengeTarget, uint256 _blkNum) internal pure returns (uint192) {
       return computeId(keccak256(abi.encodePacked(_challengerAddress, _challengeTarget)), _blkNum);
    }

    /**
    * @dev get Id for the input info
    * @param _infoHash A hash of the information
    * @param _pos Extra info
    * @return computed ID
    */
    function computeId(bytes32 _infoHash, uint256 _pos) internal pure returns (uint192)
    {
        return uint192((uint256(_infoHash) >> 105) | (_pos << 152));
    }

    function handleResponseToChallenge(StemCore.ChainStorage storage self, address _msgSender, uint _challengeIndex, bytes _recentTxs, bytes _signatures, bytes _indices, bytes _preState, bytes _inclusionProofs) public {
        require(block.timestamp.sub(self.childBlocks[self.lastChildBlockNum].timestamp) <= self.childBlockChallengePeriod, "Not in challenge period");
        require(self.childBlockChallengeId.length > _challengeIndex, "Invalid challenge index");
        // 0: txLeafIndex, 1: preStateLeafIndex, 2: stateLeafIndex
        RLP.RLPItem[] memory indices = _indices.toRLPItem().toList();
        RLP.RLPItem[] memory proofs = _inclusionProofs.toRLPItem().toList();
        // verify the state of target account before applying recent txs
        //verifyPreState(self, _preState, proofs[1].toData(), indices[1].toUint());
        require(Merkle.checkMembership(keccak256(_recentTxs), indices[0].toUint(), self.childBlocks[self.lastChildBlockNum].txTreeRoot, proofs[0].toData()), "Failed to prove the inclusion of the txs");
        // verify recent txs and get the expected current balance
        //bytes memory actualState = verifyRecentTxs(self, _challengeIndex, _preState, _recentTxs.toRLPItem().toList(), _signatures.toRLPItem().toList());

        // encode actualState
        //require(Merkle.checkMembership(keccak256(actualState), indices[1].toUint(), self.childBlocks[self.lastChildBlockNum].balanceTreeRoot, proofs[2].toData()), "Failed to prove the inclusion of the state");

        // respond to the block challenge successfully
        //_msgSender.transfer(self.blockChallengeBond);
        //removeChildBlockChallengeByIndex(self, _challengeIndex);

    }

     /**
    * @dev verify the inclusion of target state in the last confirmed state tree
    * @param _preState The state of target account in last confirmed child block
    * @param _preStateInclusionProof The merkle proof for the inclusion of the state
    * @param _preStateIndex The index of the state in the state tree
    */
    function verifyPreState(StemCore.ChainStorage storage self, bytes _preState, bytes _preStateInclusionProof, uint256 _preStateIndex) internal view {
        uint256 lastConfirmedBlkNum = StemCore.getLastConfirmedChildBlockNumber(self);
        require(Merkle.checkMembership(keccak256(_preState), _preStateIndex, self.childBlocks[lastConfirmedBlkNum].balanceTreeRoot, _preStateInclusionProof));
    }

     /**
    * @dev Verify txs of target account during last interval
    * @param _challengeIndex The index of the challenge
    * @param _preState The state of target account at the beginning of last interval
    * @param splitRecentTxs The transactions of target account during last interval
    * @param splitSignatures The signatures of the tx senders
    * @return the balance of target account after applying all txs
    */
    function verifyRecentTxs(StemCore.ChainStorage storage self, uint _challengeIndex, bytes _preState, RLP.RLPItem[] memory splitRecentTxs, RLP.RLPItem[] memory splitSignatures) internal view returns(bytes) {

        //uint256 actualBalance = _getBalanceByChallengeIndex(_challengeIndex);
        // TODO: require expectedBalance in a certain range, need to consider gas cost
        //require(actualBalance == expectedBalance, "Invalid balance");

        //uint192 challengeId = childBlockChallengeId[_challengeIndex];
        StemCore.ChildBlockChallenge memory challenge = self.childBlockChallenges[self.childBlockChallengeId[_challengeIndex]];

        //RLP.RLPItem[] memory splitRecentTxs = _recentTxs.toRLPItem().toList();
        //RLP.RLPItem[] memory splitSignatures = _signatures.toRLPItem().toList();
        require(splitRecentTxs.length == splitSignatures.length);

        // TODO: decode _preState to get Account, tempBalance and tempNonce
        RLP.RLPItem[] memory decodedPreState = _preState.toRLPItem().toList();
        require(challenge.challengeTarget == decodedPreState[0].toAddress());

        uint256 tempBalance = decodedPreState[1].toUint();
        uint256 tempNonce = decodedPreState[2].toUint();
        uint256 inspecTxCount = 0;
        RLP.RLPItem[] memory decodedInspecState;
        for (uint i = 0; i < splitRecentTxs.length; i++) {
            tempBalance = _verifySingleTx(tempBalance, tempNonce, challenge.challengeTarget, splitRecentTxs[i], splitSignatures[i]);
            tempNonce.add(1);
            //TODO consider the case that inspecTxHash is nil
            if (challenge.inspecTxHash == keccak256(splitRecentTxs[i].toData())) {
                inspecTxCount.add(1);
                //TODO: require tempBalance to be in a reasonable range
                decodedInspecState = challenge.inspecState.toRLPItem().toList();
                require(tempBalance == decodedInspecState[1].toUint());
            }
        }

        // require recent txs include inspec tx
        require(inspecTxCount == 1);
        return _encodeState(challenge.challengeTarget, tempBalance, tempNonce);
    }

    /**
     */
    function _encodeState(address account, uint256 balance, uint256 nonce) internal pure returns(bytes) {
        bytes[] memory actualStateArray = new bytes[](3);
        actualStateArray[0] = account.encodeAddress();
        actualStateArray[1] = balance.encodeUint();
        actualStateArray[2] = nonce.encodeUint();
        return actualStateArray.encodeList();
    }

    /**
    * @dev Verify the signature and amount of a single tx
    * @param _balanceBeforeTx The balance of target account before tx
    * @param _nonceBeforeTx The nonce of target account before tx
    * @param _targetAccount The account the challenger wants to examine
    * @param _tx The transaction
    * @param _signature The signature of the tx sender
    * @return the balance and nonce of target account after tx
    */
    function _verifySingleTx(uint256 _balanceBeforeTx, uint256 _nonceBeforeTx, address _targetAccount, RLP.RLPItem memory _tx, RLP.RLPItem memory _signature) internal pure returns(uint256) {

        RLP.RLPItem[] memory txItems = _tx.toList();
        address from = txItems[0].toAddress();
        address to = txItems[1].toAddress();
        uint256 amount = txItems[2].toUint();
        uint256 nonce = txItems[5].toUint();
        require(_nonceBeforeTx <= nonce, "Invalid nonce");

        require(_targetAccount == from || _targetAccount == to, "The target account is neither a sender nor a receiver");

        // verify the signature
        require(from == ECRecovery.recover(keccak256(_tx.toBytes()), _signature.toBytes()), "Invalid signature");
        if (_targetAccount == from) {
            uint256 cost = computeCost(txItems); //amount.add(gasPrice.mul(gasLimit));
            require(_balanceBeforeTx >= cost, "Balance not enough");
            return _balanceBeforeTx.sub(cost);
        } else {
            return _balanceBeforeTx.add(amount);
        }
    }

    /**
     */
    function computeCost(RLP.RLPItem[] memory txItems) internal pure returns(uint256) {
        uint256 amount = txItems[2].toUint();
        uint256 gasPrice = txItems[3].toUint();
        uint256 gasLimit = txItems[4].toUint();
        return amount.add(gasPrice.mul(gasLimit));
    }

    /**
    * @dev Remove child block challenge by its index
    * @param _index The index of the challenge
    */
    function removeChildBlockChallengeByIndex(StemCore.ChainStorage storage self, uint _index) internal {
        require(_index < self.childBlockChallengeId.length, "Invalid challenge index");
        self.childBlockChallengeId[_index] = self.childBlockChallengeId[self.childBlockChallengeId.length - 1];
        delete self.childBlockChallengeId[self.childBlockChallengeId.length - 1];
        self.childBlockChallengeId.length--;
    }
}