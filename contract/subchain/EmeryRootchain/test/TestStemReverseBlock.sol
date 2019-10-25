pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StemRootchain.sol";

contract TestStemReverseBlock {

    uint256 public initialBalance = 88234567890;

    // To use this test function, remove the condition check for challenges
    function testReverseBlock() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        address expectedOperatorAddress = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
        rootchain.addOperatorRequest.value(2234567890)(expectedOperatorAddress);
        address expectedUserAddress = 0x821aea9A577a9B44299B9c15c88CF3087F3b8888;
        rootchain.userDepositRequest.value(2234567890)(expectedUserAddress);

        // submit block[1000] and block[2000]
        address[] memory testAddresses = new address[](2);
        testAddresses[0] = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
        testAddresses[1] = 0x583031D1113aD414F02576BD6afaBfb302140225;
        uint256[] memory testBalances = new uint256[](2);
        testBalances[0] = 1234565890;
        testBalances[1] = 1234568890;
        rootchain.submitBlock.value(1234567890)(1000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 250);
        testAddresses[0] = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
        testAddresses[1] = 0x821aea9A577a9B44299B9c15c88CF3087F3b8888;
        testBalances[0] = 2234567890;
        testBalances[1] = 2234567890;
        rootchain.submitBlock.value(1234567890)(2000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 200);
        uint expected = 5;
        Assert.equal(rootchain.getOpsLen(), expected, "operators length is 5");
        Assert.equal(rootchain.getOperatorBalance(testAddresses[0]), 2234567890, "operator[0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1] = 2234567890");

        // reverse block[2000]
        // wrong block number
        //rootchain.reverseBlock(3000);
        rootchain.reverseBlock(2000);
        uint256 nextBlockNum = 2000;
        Assert.equal(rootchain.getNextChildBlockNum(), nextBlockNum, "next child block num = 2000");
        uint256 lastBlockNum = 1000;
        Assert.equal(rootchain.getLastChildBlockNum(), lastBlockNum, "last child block num = 1000");
        bytes32 txRootHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        Assert.equal(rootchain.getChildBlockTxRootHash(2000), txRootHash, "txRootHash is 0x0000000000000000000000000000000000000000000000000000000000000000");
        Assert.equal(rootchain.getOpsLen(), 4, "operators length is 4");
        Assert.equal(rootchain.getOperatorBalance(testAddresses[0]), 0, "operator[0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1] = 0");
        Assert.equal(rootchain.getOperatorFee(testAddresses[0]), 0, "operatorFee[0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1] = 0");
        Assert.equal(rootchain.isOperatorExisted(testAddresses[0]), false, "operator 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1 does not exist");
        Assert.equal(rootchain.getUserBalance(testAddresses[1]), 0, "user[0x821aea9A577a9B44299B9c15c88CF3087F3b8888] = 0");
        Assert.equal(rootchain.isUserExisted(testAddresses[1]), true, "user 0x821aea9A577a9B44299B9c15c88CF3087F3b8888 exists");
        Assert.equal(rootchain.getTotalDeposit(), 4938272560, "ExpectedTotalDeposit is 4938272560");
        Assert.equal(rootchain.getCurDepositBlockNum(), 3001, "Current deposit block number is 3001");
        Assert.equal(rootchain.getCurExitBlockNum(), 3001, "Current exit block number is 3001");

        // try to add operator
        //expectedOperatorAddress = 0xCEe66ad4a1909F6b5170deC230C1a69Bfc2B2222;
        //rootchain.addOperatorRequest.value(2234567890)(expectedOperatorAddress);

        // submit block[2000] again
        testAddresses[0] = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
        testAddresses[1] = 0x821aea9A577a9B44299B9c15c88CF3087F3b8888;
        testBalances[0] = 2234567890;
        testBalances[1] = 2234567890;
        rootchain.submitBlock.value(1234567890)(2000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 200);
        Assert.equal(rootchain.getOpsLen(), 5, "operators length is 5");
        Assert.equal(rootchain.getOperatorBalance(testAddresses[0]), 2234567890, "operator[0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1] = 2234567890");
        Assert.equal(rootchain.getNextChildBlockNum(), 3000, "next child block num = 3000");
        Assert.equal(rootchain.getLastChildBlockNum(), 2000, "last child block num = 2000");
        txRootHash = 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234;
        Assert.equal(rootchain.getChildBlockTxRootHash(2000), txRootHash, "txRootHash is 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234");

        expectedOperatorAddress = 0xCEe66ad4a1909F6b5170deC230C1a69Bfc2B2222;
        rootchain.addOperatorRequest.value(2234567890)(expectedOperatorAddress);
    }

}