pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StemRootchain.sol";

contract TestStemUserExit {

  uint256 public initialBalance = 88234567890;

    function testUserExitRequest1() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        // cancel an existing deposit request
        address expectedUserAddress = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
        rootchain.userDepositRequest.value(2234567890)(expectedUserAddress, expectedUserAddress);
        uint256 expectedDepositBlk = 1001;
        Assert.equal(rootchain.getDepositBlockNum(expectedUserAddress), expectedDepositBlk, "expectedDepositBlk is 1001");
        uint256 expectedDepositAmount = 2234567890;
        Assert.equal(rootchain.getDepositAmount(expectedUserAddress), expectedDepositAmount, "expectedDepositAmount = 2234567890");
        Assert.equal(rootchain.getContractBalance(), 10469135780, "The balance of the contract is 10469135780");
        rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 1234567890);
        expectedDepositBlk = 1001;
        Assert.equal(rootchain.getDepositBlockNum(expectedUserAddress), expectedDepositBlk, "expectedDepositBlk is 1001");
        expectedDepositAmount = 1000000000;
        Assert.equal(rootchain.getDepositAmount(expectedUserAddress), expectedDepositAmount, "expectedDepositAmount = 1000000000");
        Assert.equal(rootchain.getContractBalance(), 9234567890, "The balance of the contract is 9234567890");
        // exceeds deposit value
        //rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 1000000001);
        rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 1000000000);
        expectedDepositBlk = 0;
        Assert.equal(rootchain.getDepositBlockNum(expectedUserAddress), expectedDepositBlk, "expectedDepositBlk is 0");
        expectedDepositAmount = 0;
        Assert.equal(rootchain.getDepositAmount(expectedUserAddress), expectedDepositAmount, "expectedDepositAmount = 0");
        Assert.equal(rootchain.getContractBalance(), 8234567890, "The balance of the contract is 8234567890");
        Assert.equal(rootchain.getExitsLen(), 0, "The length of exits array is 0");
        Assert.equal(rootchain.getDepositsLen(), 0, "The length of deposits array is 0");
    }

     function testUserExitRequest2() public {
        StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
        Assert.equal(rootchain.getTotalBalance(), 4938271560, "ExpectedTotalBalance is 4938271560");
        address expectedUserAddress = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
        // the user doesn't exist in the subchain or in the deposits array
        //rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 1000000000);
        rootchain.userDepositRequest.value(2234567890)(expectedUserAddress, expectedUserAddress);
        address[] memory testAddresses;
        uint256[] memory testBalances;
        rootchain.submitBlock.value(1234567890)(1000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 0);
        testAddresses = new address[](1);
        testAddresses[0] = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
        testBalances = new uint256[](1);
        testBalances[0] = 2234567890;
        rootchain.submitBlock.value(1234567890)(2000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 0);
        Assert.equal(rootchain.getTotalBalance(), 7172839450, "ExpectedTotalBalance is 7172839450");
        Assert.equal(rootchain.getContractBalance(), 11703703670, "The balance of the contract is 11703703670");
        Assert.equal(rootchain.getUserBalance(testAddresses[0]), 2234567890, "The balance of the user is 2234567890");
        Assert.equal(rootchain.isUserExisted(testAddresses[0]), true, "User 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544 exists");
        Assert.equal(rootchain.getExitsLen(), 0, "The length of exits array is 0");
        Assert.equal(rootchain.getDepositsLen(), 1, "The length of deposits array is 1");
        rootchain.removeDepositRequest(testAddresses[0]);
        Assert.equal(rootchain.getDepositAmount(testAddresses[0]), 0, "expectedDepositAmount = 0");
        Assert.equal(rootchain.getDepositsLen(), 0, "The length of deposits array is 0");
        // wrong user exit bond
        //rootchain.userExitRequest.value(7890)(expectedUserAddress, 1000000000);
        // wrong exit amount
        //rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 3000000000);
        rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 1000000000);
        rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 1000000000);

        Assert.equal(rootchain.getExitsLen(), 1, "The length of exits array is 1");
        rootchain.submitBlock.value(1234567890)(3000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 0);
        testAddresses = new address[](1);
        testAddresses[0] = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
        testBalances = new uint256[](1);
        testBalances[0] = 234567890;
        rootchain.submitBlock.value(1234567890)(4000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 0);
        Assert.equal(rootchain.getUserBalance(testAddresses[0]), 234567890, "The balance of the user is 234567890");
        Assert.equal(rootchain.getTotalBalance(), 5172839450, "ExpectedTotalBalance is 5172839450");
        Assert.equal(rootchain.getContractBalance(), 9703703670, "The balance of the contract is 9703703670");
        // exist unresolved request
        //rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 10000);
        rootchain.removeExitRequest(expectedUserAddress);
        Assert.equal(rootchain.getExitsLen(), 0, "The length of exits array is 0");
        rootchain.userExitRequest.value(1234567890)(expectedUserAddress, 10000);
    }

}