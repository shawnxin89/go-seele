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

    event printHash(bytes32 data);
    event printBytes(bytes data);

     function testECRecovery() public {
        //bytes memory sig = hex"004c1a125d6d77fbd4feffee267f2369f202359ce94e42273b4504f17f6c55045ddcce88d1b39d62c6a0c6e73a424d3a01d2e6036be517f1932aef715f9e20a100";
        //bytes32 messageDigest = 0xb1a5cc1761e982352857bf103967aad0a90bf6369abb9caa9230762b2e53a6f1;
        bytes memory sig = hex"59e3c6790651ca38832449194a92bdd22960d6b53bf591d0eb2e5041f786127a076a7e6eb9a1d8d0d61a93995e60dbc2555d07d01d945091fac80f1815c8738c00";
        bytes32 messageDigest = 0x4cce1aa6276215c3cea7ff379de9b1d796398cf38490164422e3dcca3df50e45;
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
        StemCore.InspecBlock memory decoded = StemChallenge.decode(encoded);
        Assert.equal(decoded.creator, creator, "The expected address is 0xddb69b5181dca4d269be92819c9c7ab461be2410");
    }

    function testEncodeAddressAndUint() public {
        /*{
		    val: []interface{}{
			    "0x8cd42eebf7ccc855b303e8bba75674c8f3d0f1e1",
			    uint(10000),
			    uint(1),
		    },
		    output: "DE948CD42EEBF7CCC855B303E8BBA75674C8F3D0F1E1822710851CBE991DEF",
	    }*/
        address element1 = 0x8cd42eebf7ccc855b303e8bba75674c8f3d0f1e1;
        uint element2 = 10000;
        uint element3 = 123456789999;
        bytes[] memory bytesArray = new bytes[](3);
        bytesArray[0] = RLPEncoding.encodeAddress(element1);
        bytesArray[1] = RLPEncoding.encodeUint(element2);
        bytesArray[2] = RLPEncoding.encodeUint(element3);
        bytes memory encoded = RLPEncoding.encodeList(bytesArray);
        bytes memory expected = hex"DE948CD42EEBF7CCC855B303E8BBA75674C8F3D0F1E1822710851CBE991DEF";
        emit printBytes(encoded);
        Assert.equal(keccak256(encoded), keccak256(expected), "code not match");
    }

    function testEncodeBytes() public {
        /*{
		    val: [][]byte{
			    {0, 1, 2},
			    {3, 4, 5},
			    {6, 255},
		    },
		    output: "CB83000102830304058206FF",
        }*/
        bytes memory element1 = hex"000102";
        bytes memory element2 = hex"030405";
        bytes memory element3 = hex"06ff";
        bytes[] memory bytesArray = new bytes[](3);
        bytesArray[0] = RLPEncoding.encodeBytes(element1);
        bytesArray[1] = RLPEncoding.encodeBytes(element2);
        bytesArray[2] = RLPEncoding.encodeBytes(element3);
        bytes memory encoded = RLPEncoding.encodeList(bytesArray);
        bytes memory expected = hex"CB83000102830304058206FF";
        Assert.equal(keccak256(encoded), keccak256(expected), "code not match");
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

    // A simple example
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

        bytes[] memory bytesArray = new bytes[](3);
        bytesArray[0] = RLPEncoding.encodeAddress(testAddress);
        bytes32 byteHash = 0xc810ba2f7f7d10159a42effd535fd92e3ebf65c913dfa13fcbf874b124677bea;
        bytesArray[1] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(byteHash));
        byteHash = 0x0541f8a317ff1b9e13379d46f5d67062666b74eefad90431e9fe46b3ed7d723e;
        bytesArray[2] = RLPEncoding.encodeBytes(ByteUtils.bytes32ToBytes(byteHash));
        bytes memory inspecBlock = RLPEncoding.encodeList(bytesArray);
        //bytes32 inspecBlockHash = keccak256(inspecBlock);
        //emit printHash(inspecBlockHash);
        //bytes32 expected = 0x7ad0aaeda878288df352b2dd34ad57041ba304a726219e7861b62a013a94cf6c;
        //Assert.equal(inspecBlockHash, expected, "not match");
        bytes memory inspecBlockSignature = hex"689fd4a4732083a8bcca36950816d90b96b84cad7653e56d9c0eb4454e5da69a18a162b8893362b01e747a3d6885ce3bb761086af9dc589f48c9c9e346e44ea100";
        byteHash = 0x4cce1aa6276215c3cea7ff379de9b1d796398cf38490164422e3dcca3df50e45;
        bytes32 p1 = 0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b;
        bytes32 p2 = 0xce1009a74105bfaa44931cf2052443ee19dab7e9d0d508c2b7f3abf6200204c9;
        bytes memory proof = abi.encodePacked(p1, p2);

        bytesArray[0] = RLPEncoding.encodeAddress(testAddress);
        bytesArray[1] = RLPEncoding.encodeUint(uint256(1234565890));
        bytesArray[2] = RLPEncoding.encodeUint(uint256(1));
        bytes memory encodedState = RLPEncoding.encodeList(bytesArray);

        bytes[] memory proofArray = new bytes[](2);
        proofArray[0] = RLPEncoding.encodeBytes(proof);
        proofArray[1] = RLPEncoding.encodeBytes(proof);
        bytes memory encodedProof = RLPEncoding.encodeList(proofArray);
        proofArray[0] = RLPEncoding.encodeUint(uint256(1));
        proofArray[1] = RLPEncoding.encodeUint(uint256(1));
        bytes memory encodedIndices = RLPEncoding.encodeList(proofArray);
         // insufficient challenge bond
        //rootchain.challengeSubmittedBlock.value(34567890)(testAddress, inspecBlock, inspecBlockSignature, byteHash, encodedState, encodedIndices, encodedProof);
        rootchain.challengeSubmittedBlock.value(1234567890)(testAddress, inspecBlock, inspecBlockSignature, byteHash, encodedState, encodedIndices, encodedProof);
    }

     function testAfterChallengeSubmission() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        uint192 id = rootchain.getChallengeId(0);
        address testAddress = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
        Assert.equal(uint(id), uint(11419712055689991657431568270872319576212033412100),"Id not match");
        Assert.equal(rootchain.getChallengeTarget(id), testAddress,"challenge target not match");
        Assert.equal(rootchain.getChallengeLen(), uint256(1), "Incorrect length of challenges");
     }
}