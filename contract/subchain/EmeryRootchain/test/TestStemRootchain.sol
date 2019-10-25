pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StemRootchain.sol";

contract TestStemRootchain {

  uint256 public initialBalance = 88234567890;

  function testRootchainInitialization() public {

    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());

    uint expected = 4;
    Assert.equal(rootchain.getOpsLen(), expected, "operators length is 4");
    bytes32 name = "416e6e6965";
    Assert.equal(rootchain.getChildChainName(), name, "subchain name mismatch!");
	  address o = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
	  uint256 deposit = 1234567890;
    Assert.equal(rootchain.getOperatorBalance(o), deposit, "operator[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = 1234567890");
    uint256 fee = 0;
    Assert.equal(rootchain.getOperatorFee(o), fee, "operatorFee[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = 0");
    bytes32 expectedStaticNode = "107.105.20.39";
    Assert.equal(rootchain.getStaticNodes(0), expectedStaticNode, "staticNodes[0] = 107.105.20.39");
    uint256 expectedCreatorDeposit = 1000;
    Assert.equal(rootchain.getCreatorDeposit(), expectedCreatorDeposit, "creator deposit = 1000");
    uint256 expectedTotalDeposit = 4938272560;
    Assert.equal(rootchain.getTotalDeposit(), expectedTotalDeposit, "total deposit = 4938272560");
    uint256 nextBlockNum = 1000;
    Assert.equal(rootchain.getNextChildBlockNum(), nextBlockNum, "next child block num = 1000");
    uint256 curDepositBlockNum = 1001;
    Assert.equal(rootchain.getCurDepositBlockNum(), curDepositBlockNum, "current deposit block num = 1001");
    uint256 curExitBlockNum = 1001;
    Assert.equal(rootchain.getCurExitBlockNum(), curExitBlockNum, "current exit block num = 1001");
    address owner = 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef;
    Assert.equal(rootchain.getOwner(), owner, "owner is 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef");
    //uint256 t = rootchain.getChildBlockTimestamp(0);
    //uint256 expectedTimestamp = 1566243133;
    //Assert.equal(t, expectedTimestamp, "timestamp mismatch, that's fine");
    bytes32 txRootHash = 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823;
    Assert.equal(rootchain.getChildBlockTxRootHash(0), txRootHash, "txRootHash is 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823");
  }

  // To use this test function, please comment out require() that checks msg.sender
  function testAddOperatorRequest() public {

    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());

    address expectedOperatorAddress = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
    // registered address
    //address expectedOperatorAddress = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    // test insufficient deposit amount
    // rootchain.addOperatorRequest.value(234567890)(expectedOperatorAddress);
    rootchain.addOperatorRequest.value(2234567890)(expectedOperatorAddress);
    uint256 expectedDepositBlk = 1001;
    Assert.equal(rootchain.getDepositBlockNum(expectedOperatorAddress), expectedDepositBlk, "expectedDepositBlk is 1001");
    uint256 expectedDepositAmount = 2234567890;
    Assert.equal(rootchain.getDepositAmount(expectedOperatorAddress), expectedDepositAmount, "expectedDepositAmount = 2234567890");
    bool expectedDepositType = true;
    Assert.equal(rootchain.getDepositType(expectedOperatorAddress), expectedDepositType, "expectedDepositType = True");
    // this address exists for an existing request
    //rootchain.addOperatorRequest.value(2234567890)(expectedOperatorAddress);
  }

  // To use this test function, please comment out require() that checks msg.sender
  function testUserDepositRequest() public {

    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());

    address expectedUserAddress = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
    //address expectedUserAddress = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    // test an address previously used in addOperator request
    //address expectedUserAddress = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
    // test insufficient deposit amount
    // rootchain.addOperatorRequest.value(234567890)(expectedOperatorAddress);
    rootchain.userDepositRequest.value(2234567890)(expectedUserAddress);
    uint256 expectedDepositBlk = 1002;
    Assert.equal(rootchain.getDepositBlockNum(expectedUserAddress), expectedDepositBlk, "expectedDepositBlk is 1002");
    uint256 expectedDepositAmount = 2234567890;
    Assert.equal(rootchain.getDepositAmount(expectedUserAddress), expectedDepositAmount, "expectedDepositAmount = 2234567890");
    bool expectedDepositType = false;
    Assert.equal(rootchain.getDepositType(expectedUserAddress), expectedDepositType, "expectedDepositType = False");
    rootchain.userDepositRequest.value(2234567890)(expectedUserAddress);
    expectedDepositBlk = 1002;
    Assert.equal(rootchain.getDepositBlockNum(expectedUserAddress), expectedDepositBlk, "expectedDepositBlk is 1002");
    expectedDepositAmount = 4469135780;
    Assert.equal(rootchain.getDepositAmount(expectedUserAddress), expectedDepositAmount, "expectedDepositAmount = 4469135780");
    expectedUserAddress = 0x821aea9A577a9B44299B9c15c88CF3087F3b8888;
    rootchain.userDepositRequest.value(2234567890)(expectedUserAddress);
    expectedDepositBlk = 1003;
    Assert.equal(rootchain.getDepositBlockNum(expectedUserAddress), expectedDepositBlk, "expectedDepositBlk is 1003");

  }

  // To use this test function, please remove any condition check for msg.sender
  function testSubmitBlock() public {
    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
    uint256 expectedTotalBalance = 4938271560;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 4938271560");
    uint256 expectedTotalFee = 0;
    Assert.equal(rootchain.getTotalFee(), expectedTotalFee, "ExpectedTotalFee is 0");

    // submit block[1000]
    address[] memory testAddresses = new address[](2);
    testAddresses[0] = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    testAddresses[1] = 0x583031D1113aD414F02576BD6afaBfb302140225;
    uint256[] memory testBalances = new uint256[](2);
    testBalances[0] = 1234565890;
    testBalances[1] = 1234568890;
    // wrong blockSubmissionBond
    //rootchain.submitBlock.value(7890)(1000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 250);
    rootchain.submitBlock.value(1234567890)(1000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 250);
    uint expected = 4;
    Assert.equal(rootchain.getOpsLen(), expected, "operators length is 4");
    address expectedOperatorAddress = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    Assert.equal(rootchain.getOperatorBalance(expectedOperatorAddress), 1234565890, "operator[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB] = 1234565890");
    Assert.equal(rootchain.getAccountBackup(0), 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB, "backup account 1 is 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB");
    Assert.equal(rootchain.getBalanceBackup(0), 1234567890, "The balance of backup account 1 is 1234567890");
    Assert.equal(rootchain.getFeeBackup(), 250, "The backup fee is 250");

    uint256 nextBlockNum = 2000;
    Assert.equal(rootchain.getNextChildBlockNum(), nextBlockNum, "next child block num = 2000");
    uint256 lastBlockNum = 1000;
    Assert.equal(rootchain.getLastChildBlockNum(), lastBlockNum, "last child block num = 1000");
    uint256 curDepositBlockNum = 2001;
    Assert.equal(rootchain.getCurDepositBlockNum(), curDepositBlockNum, "current deposit block num = 2001");
    uint256 curExitBlockNum = 2001;
    Assert.equal(rootchain.getCurExitBlockNum(), curExitBlockNum, "current exit block num = 2001");
    bytes32 txRootHash = 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234;
    Assert.equal(rootchain.getChildBlockTxRootHash(1000), txRootHash, "txRootHash is 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234");
    //Assert.equal(rootchain.getChildBlockSubmitter(1000), address(this), "expectedAddress is current address");
    /*expectedTotalFee = 1000;
    Assert.equal(rootchain.getTotalFee(), expectedTotalFee, "ExpectedTotalFee is 1000");
    expectedTotalBalance = 4938270560;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 4938270560");
    uint256 expectedTotalDeposit = 4938272560;
    Assert.equal(rootchain.getTotalDeposit(), expectedTotalDeposit, "ExpectedTotalDeposit is 4938272560");
    Assert.equal(rootchain.getTotalDepositBackup(), expectedTotalDeposit, "The backup total deposit is 4938272560");*/

  }

  // To use this test function, please remove operations related to child block submitter
  function testSubmitBlock2() public {
    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());

    // submit block[2000]
    address[] memory testAddresses = new address[](5);
    testAddresses[0] = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    testAddresses[1] = 0x583031D1113aD414F02576BD6afaBfb302140225;
    testAddresses[2] = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
    testAddresses[3] = 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544;
    testAddresses[4] = 0x821aea9A577a9B44299B9c15c88CF3087F3b8888;
    uint256[] memory testBalances = new uint256[](5);
    testBalances[0] = 1234545890;
    testBalances[1] = 1234587890;
    testBalances[2] = 2234567890;
    testBalances[3] = 4469135780;
    testBalances[4] = 2234567890;
    rootchain.submitBlock.value(1234567890)(2000, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234, testAddresses, testBalances, 200);
    uint expected = 5;
    Assert.equal(rootchain.getOpsLen(), expected, "operators length is 5");
    address expectedOperatorAddress = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    Assert.equal(rootchain.getOperatorBalance(expectedOperatorAddress), 1234545890, "operator[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB] = 1234545890");
    /*Assert.equal(rootchain.getAccountBackup(0), 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB, "backup account 1 is 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB");
    Assert.equal(rootchain.getBalanceBackup(0), 1234565890, "The balance of backup account 1 is 1234565890");
    Assert.equal(rootchain.getFeeBackup(), 200, "The backup fee is 200");
    uint256 nextBlockNum = 3000;
    Assert.equal(rootchain.getNextChildBlockNum(), nextBlockNum, "next child block num = 3000");
    uint256 lastBlockNum = 2000;
    Assert.equal(rootchain.getLastChildBlockNum(), lastBlockNum, "last child block num = 2000");
    uint256 curDepositBlockNum = 3001;
    Assert.equal(rootchain.getCurDepositBlockNum(), curDepositBlockNum, "current deposit block num = 3001");
    uint256 curExitBlockNum = 3001;
    Assert.equal(rootchain.getCurExitBlockNum(), curExitBlockNum, "current exit block num = 3001");
    bytes32 txRootHash = 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234;
    Assert.equal(rootchain.getChildBlockTxRootHash(2000), txRootHash, "txRootHash is 0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d1234");*/
    uint256 expectedTotalFee = 2000;
    Assert.equal(rootchain.getTotalFee(), expectedTotalFee, "ExpectedTotalFee is 2000");
    uint256 expectedTotalBalance = 13876541120;
    Assert.equal(rootchain.getTotalBalance(), expectedTotalBalance, "ExpectedTotalBalance is 13876541120");
    uint256 expectedTotalDeposit = 13876544120;
    Assert.equal(rootchain.getTotalDeposit(), expectedTotalDeposit, "ExpectedTotalDeposit is 13876544120");
    Assert.equal(rootchain.getTotalDepositBackup(), 4938272560, "The backup total deposit is 4938272560");
    Assert.equal(rootchain.getContractBalance(), 18407407340, "The balance of the contract is 18407407340");
  }

  function testRemoveDepositRequest() public {
    StemRootchain rootchain = StemRootchain(DeployedAddresses.StemRootchain());
    address depositAddress = 0xcEE66ad4a1909F6b5170DEc230c1A69BFC2B21d1;
    uint256 expectedDepositAmount = 2234567890;
    Assert.equal(rootchain.getDepositAmount(depositAddress), expectedDepositAmount, "expectedDepositAmount = 2234567890");
    Assert.equal(rootchain.getDepositsLen(), 3, "The length of deposits array is 3");
    rootchain.removeDepositRequest(depositAddress);
    Assert.equal(rootchain.getDepositAmount(depositAddress), 0, "expectedDepositAmount = 0");
    Assert.equal(rootchain.getDepositsLen(), 2, "The length of deposits array is 2");
  }
}
