pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RLPEncoding.sol";
import "../contracts/ByteUtils.sol";
import "../contracts/Merkle.sol";
import "../contracts/BinaryMerkleTree.sol";
import "../contracts/SandboxStemRootchain.sol";

contract TestStemChallengeResponse {

    uint256 public initialBalance = 88234567890;

    event printHash(bytes32 data);

    function testBeforeChallengeResponse() public {
        SandboxStemRootchain rootchain = SandboxStemRootchain(DeployedAddresses.SandboxStemRootchain());
        rootchain.createTestChallenge();
        Assert.equal(rootchain.getChallengeTarget(rootchain.getChallengeId(0)), address(0x627306090abaB3A6e1400e9345bC60c78a8BEf57),"challenge target not match");
        Assert.equal(rootchain.getChallengeLen(), uint256(1), "Incorrect length of challenges");
    }

    // remove condition check for msg.sender, remove inclusion proof for prestate
    function testChallengeResponse() public {
        SandboxStemRootchain rootchain = SandboxStemRootchain(DeployedAddresses.SandboxStemRootchain());

        // generate tx
        // private key 0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3
        address testAddress = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        address toAddress = 0x583031D1113aD414F02576BD6afaBfb302140225;
        bytes[] memory bytesArray = new bytes[](6);
        bytesArray[0] = RLPEncoding.encodeAddress(testAddress);
        bytesArray[1] = RLPEncoding.encodeAddress(toAddress);
        bytesArray[2] = RLPEncoding.encodeUint(uint256(1000));
        bytesArray[3] = RLPEncoding.encodeUint(uint256(1));
        bytesArray[4] = RLPEncoding.encodeUint(uint256(1000));
        bytesArray[5] = RLPEncoding.encodeUint(uint256(0));
        bytes[] memory txArray = new bytes[](1);
        txArray[0] = RLPEncoding.encodeList(bytesArray);
        bytes memory encodedTxs = RLPEncoding.encodeList(txArray);
        //bytes32 txHash = keccak256(encodedTxs);
        //emit printHash(txHash);
        //bytes32 expected = 0xf2fe39ce07f729ce595d47e08b4bdd9d80d1b3b9c66e7cf47e1fe5d0b01ed5c1;
        //Assert.equal(txHash, expected, "not match");

        // tx signature
        bytes[] memory sigArray = new bytes[](1);
        sigArray[0] = RLPEncoding.encodeBytes(hex"59e3c6790651ca38832449194a92bdd22960d6b53bf591d0eb2e5041f786127a076a7e6eb9a1d8d0d61a93995e60dbc2555d07d01d945091fac80f1815c8738c00");
        bytes memory txSigs = RLPEncoding.encodeList(sigArray);

        // generate current state
        bytes[] memory stateArray = new bytes[](3);
        //stateArray[0] = RLPEncoding.encodeAddress(testAddress);
        //stateArray[1] = RLPEncoding.encodeUint(uint256(1234565890));
        //stateArray[2] = RLPEncoding.encodeUint(uint256(1));
        //bytes memory encodedState = RLPEncoding.encodeList(stateArray);
        //bytes32 stateHash = keccak256(encodedState);
        //emit printHash(stateHash);
        //bytes32 expected = 0x51787329681008d9fd7b7225ef4827d8b8897c71da399f60700701862cb8e305;
        //Assert.equal(stateHash, expected, "not match");

        // generate previous state
        stateArray[0] = RLPEncoding.encodeAddress(testAddress);
        stateArray[1] = RLPEncoding.encodeUint(uint256(1234567890));
        stateArray[2] = RLPEncoding.encodeUint(uint256(0));
        bytes memory encodedPreState = RLPEncoding.encodeList(stateArray);
        //bytes32 preStateHash = keccak256(encodedPreState);
        //emit printHash(preStateHash);
        //expected = 0x2253af04ddac0cb4431e9d349a6bb5fd06fafd4fc40b418e063e85f181b3764f;
        //Assert.equal(preStateHash, expected, "not match");

        //generate indices array
        bytes[] memory indexArray = new bytes[](3);
        indexArray[0] = RLPEncoding.encodeUint(uint256(1));
        indexArray[1] = RLPEncoding.encodeUint(uint256(1));
        indexArray[2] = RLPEncoding.encodeUint(uint256(1));
        bytes memory encodedIndices = RLPEncoding.encodeList(indexArray);

        // generate inclusion proof array
        bytes memory proof = abi.encodePacked(bytes32(0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b), bytes32(0xce1009a74105bfaa44931cf2052443ee19dab7e9d0d508c2b7f3abf6200204c9));
        bytes[] memory proofArray = new bytes[](3);
        proofArray[0] = RLPEncoding.encodeBytes(proof);
        proofArray[1] = RLPEncoding.encodeBytes(proof);
        proofArray[2] = RLPEncoding.encodeBytes(proof);
        bytes memory encodedProof = RLPEncoding.encodeList(proofArray);
        rootchain.responseToBlockChallenge(0, encodedTxs, txSigs, encodedIndices, encodedPreState, encodedProof);
    }

    function testChallengeRemoval() public {
        SandboxStemRootchain rootchain = SandboxStemRootchain(DeployedAddresses.SandboxStemRootchain());
        Assert.equal(rootchain.getChallengeLen(), uint256(0), "Incorrect length of challenges");
    }


}