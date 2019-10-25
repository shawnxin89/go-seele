pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StemRootchain.sol";

contract TestStemOperatorExit {

  uint256 public initialBalance = 88234567890;

  // To use this test function, please remove any condition check for msg.sender
  function testOperatorExitRequest() public {
    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
    Assert.equal(rootchain.getContractBalance(), 8234567890, "The balance of the contract is 8234567890");
    uint256 expectedTotalBalance = 4938271560;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 4938271560");
    // cancel an existing deposit request
    address expectedOperatorAddress = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
    rootchain.addOperatorRequest.value(2234567890)(expectedOperatorAddress);
    uint256 expectedDepositBlk = 1001;
    Assert.equal(rootchain.getDepositBlockNum(expectedOperatorAddress), expectedDepositBlk, "expectedDepositBlk is 1001");
    uint256 expectedDepositAmount = 2234567890;
    Assert.equal(rootchain.getDepositAmount(expectedOperatorAddress), expectedDepositAmount, "expectedDepositAmount = 2234567890");
    Assert.equal(rootchain.getContractBalance(), 10469135780, "The balance of the contract is 10469135780");
    rootchain.operatorExitRequest.value(1234567890)(expectedOperatorAddress);
    expectedDepositBlk = 0;
    Assert.equal(rootchain.getDepositBlockNum(expectedOperatorAddress), expectedDepositBlk, "expectedDepositBlk is 0");
    expectedDepositAmount = 0;
    Assert.equal(rootchain.getDepositAmount(expectedOperatorAddress), expectedDepositAmount, "expectedDepositAmount = 0");
    Assert.equal(rootchain.getContractBalance(), 8234567890, "The balance of the contract is 8234567890");

    // new exit request
    address operatorToExit = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    // insufficient exit bond
    //rootchain.operatorExitRequest.value(7890)(operatorToExit);
    // wrong operator address
    // address operatorToExit = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
    rootchain.operatorExitRequest.value(1234567890)(operatorToExit);
    uint256 expectedExitBlk = 1001;
    Assert.equal(rootchain.getExitBlockNum(operatorToExit), expectedExitBlk, "expectedExitBlk is 1001");
    uint256 expectedExitAmount = 1234567890;
    Assert.equal(rootchain.getExitAmount(operatorToExit), expectedExitAmount, "expectedExitAmount = 1234567890");
    bool expectedExitType = true;
    Assert.equal(rootchain.getExitType(operatorToExit), expectedExitType, "expectedExitType = True");
    uint256 expectedCurExitBlk = 1001;
    Assert.equal(rootchain.getCurExitBlockNum(), expectedCurExitBlk, "expectedCurExitBlk is 1001");
    // repeated request
    rootchain.operatorExitRequest.value(1234567890)(operatorToExit);
    expectedExitBlk = 1001;
    Assert.equal(rootchain.getExitBlockNum(operatorToExit), expectedExitBlk, "expectedExitBlk is 1001");
    expectedExitAmount = 1234567890;
    Assert.equal(rootchain.getExitAmount(operatorToExit), expectedExitAmount, "expectedExitAmount = 1234567890");
  }

  // To use this test function, please remove any condition check for msg.sender
  function testSubmitBlock3() public {
    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
    address[] memory testAddresses;
    uint256[] memory testBalances;
    rootchain.submitBlock.value(1234567890)(1000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 0);
    uint256 expectedTotalBalance = 4938271560;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 4938271560");
    Assert.equal(rootchain.getContractBalance(), 10703703670, "The balance of the contract is 10703703670");
    uint expected = 4;
    Assert.equal(rootchain.getOpsLen(), expected, "operators length is 4");

    rootchain.submitBlock.value(1234567890)(2000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 0);
    expectedTotalBalance = 3703703670;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 3703703670");
    Assert.equal(rootchain.getContractBalance(), 8234567890, "The balance of the contract is 8234567890");
    expected = 3;
    Assert.equal(rootchain.getOpsLen(), expected, "operators length is 3");
    address exitedOperator = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    Assert.equal(rootchain.getOperatorBalance(exitedOperator), 0, "operator[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = 0");

    rootchain.execOperatorExit(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c);
    expectedTotalBalance = 3703703670;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 3703703670");
    Assert.equal(rootchain.getContractBalance(), 8234567890, "The balance of the contract is 8234567890");
    expected = 3;
    Assert.equal(rootchain.getOpsLen(), expected, "operators length is 3");
    exitedOperator = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    Assert.equal(rootchain.getOperatorBalance(exitedOperator), 0, "operator[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = 0");

  }

  function testRemoveOperatorExitRequest() public {
      StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
      address exitedOperator = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
      Assert.equal(rootchain.getExitBlockNum(exitedOperator), 1001, "expectedExitBlk is 1001");
      Assert.equal(rootchain.getExitAmount(exitedOperator), 1234567890, "expectedExitAmount = 1234567890");
      Assert.equal(rootchain.getExitStatus(exitedOperator), true, "The exit request has been executed");
      Assert.equal(rootchain.getExitsLen(), 1, "The length of exits array is 1");

      rootchain.removeExitRequest(exitedOperator);
      Assert.equal(rootchain.getExitBlockNum(exitedOperator), 0, "expectedExitBlk is 0");
      Assert.equal(rootchain.getExitAmount(exitedOperator), 0, "expectedExitAmount = 0");
      Assert.equal(rootchain.getExitStatus(exitedOperator), false, "The exit request has been removed");
      Assert.equal(rootchain.getExitsLen(), 0, "The length of exits array is 0");
  }

  // To use this test function, please remove any condition check for msg.sender  
  function testFeeExit() public {
      StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
      address[] memory testAddresses = new address[](2);
      testAddresses[0] = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      testAddresses[1] = 0x583031D1113aD414F02576BD6afaBfb302140225;
      uint256[] memory testBalances = new uint256[](2);
      testBalances[0] = 1234565890;
      testBalances[1] = 1234568890;
      rootchain.submitBlock.value(1234567890)(3000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 333);
      Assert.equal(rootchain.getOperatorFee(testAddresses[0]), 333, "The operator fee of 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB is 333");
      // wrong exit amount
      // rootchain.feeExit(testAddresses[0], 340);
      rootchain.feeExit(testAddresses[0], 300);
      Assert.equal(rootchain.getOperatorFee(testAddresses[0]), 33, "The operator fee of 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB is 33");
  }
}