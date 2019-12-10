pragma solidity ^0.4.24;

// external modules
import "./ECRecovery.sol";
import "./Merkle.sol";
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
    using SafeMath for uint256;

    event BlockChallenge(address challengeTarget, uint256 blkNum);
    event RemoveBlockChallenge(uint challengeIndex);
    /**
    * @dev Process new child block challenge
    * @param _encodedAddresses  Msg sender and the challenge target
    * @param _inspecBlock  The block containing the inspec tx (structure: creator/txTreeRoot/stateTreeRoot)
    * @param _inspecBlockSignature  The block signature signed by the block producer
    * @param _inspecTxHash  The tx hash provided by the challenger(default 0x0)
    * @param _inspecState   The state of the target address after the inspec tx
    * @param _indices  0._inspecTxIndex The tx index in the merkle tree; 1._inspecStateIndex The state index in the merkle tree
    * @param _inclusionProofs 0. The proof showing _inspecTxHash is included in _inspecBlock; 1._stateInclusionProof The proof showing _inspecState is in _inspecBlock
     */
    function processChallenge(StemCore.ChainStorage storage self, bytes _encodedAddresses, bytes _inspecBlock, bytes _inspecBlockSignature, bytes32 _inspecTxHash, bytes _inspecState, bytes _indices, bytes _inclusionProofs) 
    public {
        require(self.isFrozen == false, "The subchain is frozen");
        // make sure it is within challenge submission period
        require(block.timestamp.sub(self.childBlocks[self.lastChildBlockNum].timestamp) <= self.childBlockChallengeSubmissionPeriod, "Not in challenge submission period");

        RLP.RLPItem[] memory addresses = _encodedAddresses.toRLPItem().toList();
         // Challenge target must exist.
        require(self.isExistedUsers[addresses[1].toAddress()] || self.isExistedOperators[addresses[1].toAddress()], "The challenge target doesn't exist!");

        if (_inspecBlock.length > 0) {
            require(_indices.length > 0 && _inclusionProofs.length > 0, "Invalid length");
            RLP.RLPItem[] memory indices = _indices.toRLPItem().toList();
            RLP.RLPItem[] memory proofs = _inclusionProofs.toRLPItem().toList();

            // decode _inspecBlock
            StemCore.InspecBlock memory decodedBlock = decode(_inspecBlock);
            require(self.isExistedOperators[decodedBlock.creator], "The block is not created by existing operators");
            require(decodedBlock.height <= self.lastChildBlockNum && decodedBlock.height > self.lastChildBlockNum.sub(self.CHILD_BLOCK_INTERVAL), "The block is not in last period");
            require(decodedBlock.creator == ECRecovery.recover(keccak256(_inspecBlock), _inspecBlockSignature), "Invalid signature");
            require(Merkle.checkMembership(_inspecTxHash, indices[0].toUint(), decodedBlock.txTreeRoot, proofs[0].toData()), "Failed to prove the inclusion of the tx");
            // production environment
            //require(Merkle.checkMembership(keccak256(_inspecState), indices[1].toUint(), decodedBlock.balanceTreeRoot, proofs[1].toData()), "Failed to prove the inclusion of the state");
            createChildBlockChallenge(self, addresses[0].toAddress(), addresses[1].toAddress(), _inspecTxHash, _inspecState);
        } else {
            require(isAccountUpdated(self, addresses[1].toAddress()), "The target account wasn't updated by last submitted child block");
            createChildBlockChallenge(self, addresses[0].toAddress(), addresses[1].toAddress(), bytes32(0), "");
        }
    }

    /**
    * @dev Check whether the input account is updated by most recent
    *      submitted block
    * @param _targetAddress target address
     */
    function isAccountUpdated(StemCore.ChainStorage storage self, address _targetAddress) internal view returns (bool) {
        for (uint i = 0; i < self.accountsBackup.length; i++) {
            if (self.accountsBackup[i] == _targetAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Create new child block challenge
    * @param _challengerAddress The address of the challenger
    * @param _challengeTarget The challenge target
    * @param _inspecTxHash  The tx hash provided by the challenger(default 0x0)
    * @param _inspecState   The state of the target address after the inspec tx
     */
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
        emit BlockChallenge(_challengeTarget, self.lastChildBlockNum);
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

    /**
    * @dev Handle the response to block challenges. If the response is valid, remove the corresponding challenge
    * @param _challengeIndex The index of the challenge(TODO: change it the challenge ID)
    * @param _recentTxs Txs during the last interval
    * @param _signatures Tx signatures
    * @param _indices   The indices of the leaves in the merkle trees (tx tree/previous State tree/new state tree)
    * @param _preState  RLP encoded previous state (account:balance:nonce)
    * @param _inclusionProofs The inclusion proofs of rencentTxs/previous State/Current State
     */
    function handleResponseToChallenge(StemCore.ChainStorage storage self, uint _challengeIndex, bytes _recentTxs, bytes _signatures, bytes _indices, bytes _preState, bytes _inclusionProofs, address _msgSender) public {
        // production environment
        //require(block.timestamp.sub(self.childBlocks[self.lastChildBlockNum].timestamp) <= self.childBlockChallengePeriod, "Not in challenge period");
        require(self.isFrozen == false, "The subchain is frozen");
        require(self.childBlockChallengeId.length > _challengeIndex, "Invalid challenge index");
        // 0: txLeafIndex, 1: preStateLeafIndex, 2: stateLeafIndex
        RLP.RLPItem[] memory indices = _indices.toRLPItem().toList();
        RLP.RLPItem[] memory proofs = _inclusionProofs.toRLPItem().toList();
        require(indices.length == 3 && proofs.length == 3, "Invalid indices/proofs length");
        // verify the state of target account before applying recent txs
        // production environment
        //verifyPreState(self, _preState, proofs[1].toData(), indices[1].toUint());
        require(Merkle.checkMembership(keccak256(_recentTxs), indices[0].toUint(), self.childBlocks[self.lastChildBlockNum].txTreeRoot, proofs[0].toData()), "Failed to prove the inclusion of the txs");
        // verify recent txs and get the expected current balance
        bytes memory actualState = verifyRecentTxs(self, _challengeIndex, _preState, _recentTxs.toRLPItem().toList(), _signatures.toRLPItem().toList());

        // encode actualState
        require(Merkle.checkMembership(keccak256(actualState), indices[1].toUint(), self.childBlocks[self.lastChildBlockNum].balanceTreeRoot, proofs[2].toData()), "Failed to prove the inclusion of the state");

        // respond to the block challenge successfully
        // production environment
        //_msgSender.transfer(self.blockChallengeBond);
        // for test only
        _msgSender = 0x583031D1113aD414F02576BD6afaBfb302140225;
        _msgSender.transfer(self.blockChallengeBond);
        removeChildBlockChallengeByIndex(self, _challengeIndex);
        emit RemoveBlockChallenge(_challengeIndex);
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
        // TODO compare preState balance with the balance at last confirmed block (operaters[account] or users[account])
    }

     /**
    * @dev Verify txs of target account during last interval
    * @param _challengeIndex The index of the challenge
    * @param _preState The state of target account at the beginning of last interval
    * @param _splitRecentTxs The transactions of target account during last interval
    * @param _splitSignatures The signatures of the tx senders
    * @return the balance of target account after applying all txs
    */
    function verifyRecentTxs(StemCore.ChainStorage storage self, uint _challengeIndex, bytes _preState, RLP.RLPItem[] memory _splitRecentTxs, RLP.RLPItem[] memory _splitSignatures) internal view returns(bytes) {

        StemCore.ChildBlockChallenge memory challenge = self.childBlockChallenges[self.childBlockChallengeId[_challengeIndex]];

        require(_splitRecentTxs.length == _splitSignatures.length);

        uint256 tempBalance;
        uint256 tempNonce;
        (tempBalance, tempNonce) = _decodeState(_preState, challenge.challengeTarget);
        require(isValidPreBalance(self, challenge.challengeTarget, tempBalance), "Previous balance invalid");
        uint reqType = 0;
        if (self.deposits[challenge.challengeTarget].blkNum > self.lastChildBlockNum.sub(self.CHILD_BLOCK_INTERVAL) && self.deposits[challenge.challengeTarget].blkNum <= self.lastChildBlockNum) {
            reqType = 1;
        }
        if (self.exits[challenge.challengeTarget].blkNum > self.lastChildBlockNum.sub(self.CHILD_BLOCK_INTERVAL) && self.exits[challenge.challengeTarget].blkNum <= self.lastChildBlockNum) {
            reqType = 2;
        }
        uint256 inspecTxCount = 0;
        RLP.RLPItem[] memory decodedInspecState;
        for (uint i = 0; i < _splitRecentTxs.length; i++) {
            (tempNonce, tempBalance) = _verifySingleTx(self, [reqType, i], tempBalance, tempNonce, challenge.challengeTarget, _splitRecentTxs[i], _splitSignatures[i]);
            if (challenge.inspecTxHash == keccak256(_splitRecentTxs[i].toBytes())) {
                inspecTxCount = inspecTxCount.add(1);
                //TODO: require tempBalance to be in a reasonable range
                decodedInspecState = challenge.inspecState.toRLPItem().toList();
                require(tempBalance == decodedInspecState[1].toUint());
            }
        }

        // require recent txs to include inspec tx
        if (challenge.inspecTxHash != bytes32(0)) {
            require(inspecTxCount == uint256(1));
        }
        // compare tempBalance with the balance of the target account (operaters[account] or users[account])
        if (self.isExistedOperators[challenge.challengeTarget]) {
            require(tempBalance == self.operators[challenge.challengeTarget], "Operator balance not match");
        } else {
            require(tempBalance == self.users[challenge.challengeTarget], "User balance not match");
        }
        return _encodeState(challenge.challengeTarget, tempBalance, tempNonce);
    }

     /**
    * @dev Check whether the input account is updated by most recent
    *      submitted block
    * @param _targetAddress target address
     */
    function isValidPreBalance(StemCore.ChainStorage storage self, address _targetAddress, uint256 _preBalance) internal view returns (bool) {
        for (uint i = 0; i < self.accountsBackup.length; i++) {
            if (self.accountsBackup[i] == _targetAddress) {
                if (self.balancesBackup[i] == _preBalance) {
                    return true;
                } else {
                    return false;
                }
            }
        }
        if (self.isExistedOperators[_targetAddress]) {
            return (_preBalance == self.operators[_targetAddress]);
        } else {
            return (_preBalance == self.users[_targetAddress]);
        }
        return false;
    }

    /**
    * @dev decode state
    * @return Return balance and nonce value in the state
     */
    function _decodeState(bytes _state, address _target) internal pure returns(uint, uint){
        RLP.RLPItem[] memory decodedState = _state.toRLPItem().toList();
        require(decodedState.length == 3, "Invalid state length");
        require(_target == decodedState[0].toAddress(), "State account doesn't match target account");

        return (decodedState[1].toUint(), decodedState[2].toUint());
    }

    /**
    * @dev RLP encode account, balance and nonce into an account state
    * @param _account Account
    * @param _balance Balance
    * @param _nonce  Nonce
    * @return the bytes of the RLP encoded state
     */
    function _encodeState(address _account, uint256 _balance, uint256 _nonce) internal pure returns(bytes) {
        bytes[] memory stateArray = new bytes[](3);
        stateArray[0] = _account.encodeAddress();
        stateArray[1] = _balance.encodeUint();
        stateArray[2] = _nonce.encodeUint();
        return stateArray.encodeList();
    }

    /**
    * @dev Verify the signature and amount of a single tx
    * @param _indices [reqType, txIndex]. reqType: 1 - deposit, 2 - exit, 3 - other; txIndex: the tx No in the submitted txs
    * @param _balanceBeforeTx The balance of target account before tx
    * @param _nonceBeforeTx The nonce of target account before tx
    * @param _targetAccount The account the challenger wants to examine
    * @param _tx The transaction
    * @param _signature The signature of the tx sender
    * @return the nonce and balance of target account after tx
    */
    function _verifySingleTx(StemCore.ChainStorage storage self, uint[2] _indices, uint256 _balanceBeforeTx, uint256 _nonceBeforeTx, address _targetAccount, RLP.RLPItem memory _tx, RLP.RLPItem memory _signature) internal view returns(uint256, uint256) {

        RLP.RLPItem[] memory txItems = _tx.toList();
        address from = txItems[0].toAddress();
        address to = txItems[1].toAddress();
        uint256 amount = txItems[2].toUint();
        uint256 nonce = txItems[5].toUint();
        require(_nonceBeforeTx <= nonce, "Invalid nonce");

        require(_targetAccount == from || _targetAccount == to, "The target account is neither a sender nor a receiver");
        if (_indices[1] == 0) {
            if (_indices[0] == 0) {
                require(from != self.mintAccount && from != self.meltAccount, "Should not have any deposit/exit tx");
            }
            if (_indices[0] == 1) {
                require(from == self.mintAccount && self.deposits[_targetAccount].amount == amount, "Not match with deposit request");
            }
            if (_indices[0] == 2) {
                require(from == self.meltAccount && self.exits[_targetAccount].amount == amount, "Not match with exit request");
            }
        } else {
            require(from != self.mintAccount && from != self.meltAccount, "Should not have any deposit/exit tx");
        }
        // verify the signature
        require(from == ECRecovery.recover(keccak256(_tx.toBytes()), _signature.toData()), "Invalid signature");
        if (_targetAccount == from) {
            uint256 cost = computeCost(txItems);
            require(_balanceBeforeTx >= cost, "Balance not enough");
            return (nonce + 1, _balanceBeforeTx.sub(cost));
        } else {
            if (from == self.meltAccount) {
                return (_nonceBeforeTx, _balanceBeforeTx.sub(amount));
            }
            return (_nonceBeforeTx, _balanceBeforeTx.add(amount));
        }
    }

    /**
    * @dev Compute the cost of a tx
    * @param _txItems The tx
     */
    function computeCost(RLP.RLPItem[] memory _txItems) internal pure returns(uint256) {
        uint256 amount = _txItems[2].toUint();
        uint256 gasPrice = _txItems[3].toUint();
        uint256 gasLimit = _txItems[4].toUint();
        return amount.add(gasPrice.mul(gasLimit));
    }

    /**
    * @dev Remove child block challenge by its index
    * @param _index The index of the challenge
    */
    function removeChildBlockChallengeByIndex(StemCore.ChainStorage storage self, uint _index) internal {
        require(_index < self.childBlockChallengeId.length, "Invalid challenge index");
        for (uint i = _index; i < self.childBlockChallengeId.length - 1; i++) {
            self.childBlockChallengeId[i] = self.childBlockChallengeId[i + 1];
        }
        delete self.childBlockChallengeId[self.childBlockChallengeId.length - 1];
        self.childBlockChallengeId.length--;
    }

     /**
    * @dev Decode the RLP encoded inspec block
    * @param _inspecBlock RLP(creator, txTreeRoot, balanceTreeRoot)
     */
    function decode(bytes _inspecBlock) internal pure returns (StemCore.InspecBlock)
    {
        RLP.RLPItem[] memory inputs = _inspecBlock.toRLPItem().toList();
        require(inputs.length == 4, "Invalid inspecBlock length");
        StemCore.InspecBlock memory decodedBlock;

        decodedBlock.creator = inputs[0].toAddress();
        decodedBlock.height = inputs[1].toUint();
        decodedBlock.txTreeRoot = inputs[2].toBytes32();
        decodedBlock.balanceTreeRoot = inputs[3].toBytes32();
        return decodedBlock;
    }
}