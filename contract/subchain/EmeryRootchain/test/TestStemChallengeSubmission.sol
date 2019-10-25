pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RLPEncoding.sol";
import "../contracts/ByteUtils.sol";
import "../contracts/Merkle.sol";
import "../contracts/BinaryMerkleTree.sol";
import "../contracts/StemRootchain.sol";

contract TestStemChallengeSubmission {

    uint256 public initialBalance = 88234567890;

    //bytes[] bytesArray;
    event printHash(bytes32 data);

    function testBeforeChallengeSubmission() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        // submit block[1000]
        address[] memory testAddresses0;
        uint256[] memory testBalances0;
        rootchain.submitBlock.value(1234567890)(1000, 0x461e1a3a6e69fcf502f87941c8065bc0ef02c13160d151bfbec8797d91f6a1fb, 0xc810ba2f7f7d10159a42effd535fd92e3ebf65c913dfa13fcbf874b124677bbb, testAddresses0, testBalances0, 0);
        // submit block[2000]
        address[] memory testAddresses = new address[](2);
        testAddresses[0] = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        testAddresses[1] = 0x583031D1113aD414F02576BD6afaBfb302140225;
        uint256[] memory testBalances = new uint256[](2);
        testBalances[0] = 1234565890;
        testBalances[1] = 1234568890;
        rootchain.submitBlock.value(1234567890)(2000, 0x0541f8a317ff1b9e13379d46f5d67062666b74eefad90431e9fe46b3ed7d723e, 0x0bb650a613bd81bb21db5a56b3a455c6b2e2c79cc2ad75c19f12f86c77e84fa4, testAddresses, testBalances, 250);
    }

    /*function testChallengeSubmission() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        address testAddress = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        bytes32 txTreeRoot = 0xdfab7459798921b319c195f457dcb92795269b2de640f07656bdddeee665e530;
        bytes32 balanceTreeRoot = 0xdfab7459798921b319c195f457dcb92795269b2de640f07656bdddeee665e530;
        bytes[] memory bytesArray = new bytes[](3);
        bytesArray[0] = RLPEncoding.encodeAddress(testAddress);
        bytesArray[1] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(txTreeRoot));
        bytesArray[2] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(balanceTreeRoot));
        bytes memory inspecBlock = RLPEncoding.encodeList(bytesArray);
        bytes32 inspecBlockHash = keccak256(inspecBlock);
        emit printHash(inspecBlockHash);
        bytes32 expected = 0x6446f6c097a31321d4c5e0af1d6c45b7c163c4d54a13d898c4958f7576d4aa0e;
        Assert.equal(inspecBlockHash, expected, "not match");
        bytes memory inspecBlockSignature = hex"813be34f1d140985c31a2f47e5bb180e2c5bbbeaeb4f84c47552654331b4ae4f7ce5bad8adf99389f3e38e1375f3b56fa0534dada75d273d6a03d7fa48947d9e00";
        bytes32 leaf = 0xc65a7bb8d6351c1cf70c95a316cc6a92839c986682d98bc35f958f4883f9d2a8;
        bytes32 p1 = 0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b;
        bytes32 p2 = 0xce1009a74105bfaa44931cf2052443ee19dab7e9d0d508c2b7f3abf6200204c9;
        bytes memory proof = abi.encodePacked(p1, p2);
        // insufficient challenge bond
        //rootchain.challengeSubmittedBlock.value(34567890)(testAddress, inspecBlock, inspecBlockSignature, leaf, 1, proof, abi.encodePacked(uint256(10)), 1, proof);
        rootchain.challengeSubmittedBlock.value(1234567890)(testAddress, inspecBlock, inspecBlockSignature, leaf, 1, proof, abi.encodePacked(uint256(10)), 1, proof);
        uint192 id = rootchain.getChallengeId(0);
        Assert.equal(uint(id), uint(11419712055689991657431568270872319576212033412100),"Id not match");
        Assert.equal(rootchain.getChallengeTarget(id), testAddress,"challenge target not match");
        Assert.equal(rootchain.getChallengeLen(), uint256(1), "Incorrect length of challenges");
    }*/

    // real tx
    function testChallengeSubmission() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        address testAddress = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        bytes32 txTreeRoot = 0xc810ba2f7f7d10159a42effd535fd92e3ebf65c913dfa13fcbf874b124677bea;
        bytes32 balanceTreeRoot = 0x0541f8a317ff1b9e13379d46f5d67062666b74eefad90431e9fe46b3ed7d723e;
        bytes[] memory bytesArray = new bytes[](3);
        bytesArray[0] = RLPEncoding.encodeAddress(testAddress);
        bytesArray[1] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(txTreeRoot));
        bytesArray[2] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(balanceTreeRoot));
        bytes memory inspecBlock = RLPEncoding.encodeList(bytesArray);
        //bytes32 inspecBlockHash = keccak256(inspecBlock);
        //emit printHash(inspecBlockHash);
        //bytes32 expected = 0x7ad0aaeda878288df352b2dd34ad57041ba304a726219e7861b62a013a94cf6c;
        //Assert.equal(inspecBlockHash, expected, "not match");
        bytes memory inspecBlockSignature = hex"689fd4a4732083a8bcca36950816d90b96b84cad7653e56d9c0eb4454e5da69a18a162b8893362b01e747a3d6885ce3bb761086af9dc589f48c9c9e346e44ea100";
        bytes32 leaf = 0x4cce1aa6276215c3cea7ff379de9b1d796398cf38490164422e3dcca3df50e45;
        bytes32 p1 = 0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b;
        bytes32 p2 = 0xce1009a74105bfaa44931cf2052443ee19dab7e9d0d508c2b7f3abf6200204c9;
        bytes memory proof = abi.encodePacked(p1, p2);
        bytes[] memory stateArray = new bytes[](3);
        stateArray[0] = RLPEncoding.encodeAddress(testAddress);
        stateArray[1] = RLPEncoding.encodeUint(uint256(1234565890));
        stateArray[2] = RLPEncoding.encodeUint(uint256(1));
        bytes memory encodedState = RLPEncoding.encodeList(stateArray);
        // insufficient challenge bond
        //rootchain.challengeSubmittedBlock.value(34567890)(testAddress, inspecBlock, inspecBlockSignature, leaf, 1, proof, abi.encodePacked(uint256(10)), 1, proof);
        rootchain.challengeSubmittedBlock.value(1234567890)(testAddress, inspecBlock, inspecBlockSignature, leaf, 1, proof, encodedState, 1, proof);
        uint192 id = rootchain.getChallengeId(0);
        Assert.equal(uint(id), uint(11419712055689991657431568270872319576212033412100),"Id not match");
        Assert.equal(rootchain.getChallengeTarget(id), testAddress,"challenge target not match");
        Assert.equal(rootchain.getChallengeLen(), uint256(1), "Incorrect length of challenges");
    }

    function testECRecovery() public {
        //bytes memory sig = hex"004c1a125d6d77fbd4feffee267f2369f202359ce94e42273b4504f17f6c55045ddcce88d1b39d62c6a0c6e73a424d3a01d2e6036be517f1932aef715f9e20a100";
        //bytes32 messageDigest = 0xb1a5cc1761e982352857bf103967aad0a90bf6369abb9caa9230762b2e53a6f1;
        bytes memory sig = hex"4b2103f096e7b68dcdee01c61ae152d0514d3dc2f19f99f1da5078e8595243271072d38fcfbbe117ac00986e4f35842307f14eaaa13c62f95ab09122bf3c46e400";
        bytes32 messageDigest = 0x241f3c7dff21ec084f5c849438c7cad6d804a85f7b161fac249c0234119ff142;
        address recoveredAddress = ECRecovery.recover(messageDigest, sig);
        // Seele address
        //address expectedAddress = 0x8cd42eebf7ccc855b303e8bba75674c8f3d0f1e1;
        // Ethereum address
        //address expectedAddress = 0xDdB69b5181dcA4d269bE92819C9c7AB461bE2410;
        address expectedAddress = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        //bytes memory recoveredAddressBytes = abi.encodePacked(recoveredAddress);
        //recoveredAddressBytes[19] = recoveredAddressBytes[19] & 0xF0;
        //recoveredAddressBytes[19] = recoveredAddressBytes[19] | byte(1);
        //recoveredAddress = ByteUtils.bytesToAddress(recoveredAddressBytes);
        //uint256 recoveredAddressUint = ByteUtils.bytesToUint(recoveredAddressBytes);
        //uint256 expectedAddressUint = ByteUtils.bytesToUint(abi.encodePacked(expectedAddress));
        Assert.equal(recoveredAddress, expectedAddress, "The expected address is 0x627306090abaB3A6e1400e9345bC60c78a8BEf57");
    }

    function testEncodeBlock() public {
        address creator = 0xDdB69b5181dcA4d269bE92819C9c7AB461bE2410;
        bytes32 txTreeRoot = 0xb1a5cc1761e982352857bf103967aad0a90bf6369abb9caa9230762b2e53a6f1;
        bytes32 balanceTreeRoot = 0xb1a5cc1761e982352857bf103967aad0a90bf6369abb9caa9230762b2e53a6f1;
        bytes[] memory bytesArray = new bytes[](3);
        bytesArray[0] = RLPEncoding.encodeAddress(creator);
        bytesArray[1] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(txTreeRoot));
        bytesArray[2] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(balanceTreeRoot));
        bytes memory encoded = RLPEncoding.encodeList(bytesArray);
        StemCore.InspecBlock memory decoded = StemCore.decode(encoded);
        Assert.equal(decoded.creator, creator, "The expected address is 0xddb69b5181dca4d269be92819c9c7ab461be2410");
    }

    function testMerkleTree() public {
        BinaryMerkleTree testTree = BinaryMerkleTree(DeployedAddresses.BinaryMerkleTree());
        bytes32[] memory testData = new bytes32[](3);
        testData[0] = 0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b;
        testData[1] = 0xf2fe39ce07f729ce595d47e08b4bdd9d80d1b3b9c66e7cf47e1fe5d0b01ed5c1; //0xc65a7bb8d6351c1cf70c95a316cc6a92839c986682d98bc35f958f4883f9d2a8;
        testData[2] = 0xce6d7b5282bd9a3661ae061feed1dbda4e52ab073b1f9285be6e155d9c38d4ec;
        /*uint256[] memory testData = new uint256[](3);
        testData[0] = 3;
        testData[1] = 10;
        testData[2] = 20;*/
        Assert.equal(testTree.createTree(testData), true, "Failed to create a new Merkle tree");
        bytes32 rootHash = 0x0bb650a613bd81bb21db5a56b3a455c6b2e2c79cc2ad75c19f12f86c77e84fa4; //0xdfab7459798921b319c195f457dcb92795269b2de640f07656bdddeee665e530;
        Assert.equal(testTree.root(), rootHash, "The root hashes don't match");
        bytes32 leaf = 0xf2fe39ce07f729ce595d47e08b4bdd9d80d1b3b9c66e7cf47e1fe5d0b01ed5c1;
        bytes32 p1 = 0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b;
        bytes32 p2 = 0xce1009a74105bfaa44931cf2052443ee19dab7e9d0d508c2b7f3abf6200204c9;
        bytes memory proof = abi.encodePacked(p1, p2);
        Assert.equal(Merkle.checkMembership(leaf, 1, rootHash, proof), true, "Target not found in the Merkel tree");
    }

    // remove condition check for msg.sender, remove inclusion proof for prestate
    /*function testChallengeResponse() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());

        // generate tx
        address testAddress = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57; // private key 0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3
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
    }*/


}