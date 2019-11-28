var ECRecovery = artifacts.require("./ECRecovery.sol");
var RLPEncoding = artifacts.require("./RLPEncoding.sol");
var ByteUtils = artifacts.require("./ByteUtils.sol");
var PriorityQueue = artifacts.require("./PriorityQueue.sol");
var Merkle = artifacts.require("./Merkle.sol");
var BinaryMerkleTree = artifacts.require("./BinaryMerkleTree.sol");
var StemCore = artifacts.require("./StemCore.sol");
var StemChallenge = artifacts.require("./StemChallenge.sol");
var StemRelay = artifacts.require("./StemRelay.sol");
var StemRootchain = artifacts.require("./StemRootchain.sol");
var SandboxStemRootchain = artifacts.require("./SandboxStemRootchain.sol");
var StemCreation = artifacts.require("./StemCreation.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(ECRecovery);
  deployer.deploy(RLPEncoding);
  deployer.deploy(ByteUtils);
  deployer.deploy(PriorityQueue);
  deployer.deploy(Merkle);
  deployer.deploy(BinaryMerkleTree);
  deployer.deploy(StemCore);
  deployer.link(StemCore, StemChallenge);
  deployer.link(ECRecovery, StemChallenge);
  deployer.link(ByteUtils, StemChallenge);
  deployer.deploy(StemChallenge);
  deployer.link(StemCore, StemRelay);
  deployer.link(StemChallenge, StemRelay);
  deployer.deploy(StemRelay);
  deployer.link(StemCore, StemCreation);
  deployer.link(StemRelay, StemCreation);
  deployer.deploy(StemCreation);
  deployer.link(ECRecovery, StemRootchain);
  deployer.link(PriorityQueue, StemRootchain);
  deployer.link(StemCore, StemRootchain);
  deployer.link(StemChallenge, StemRootchain);
  deployer.link(StemRelay, StemRootchain);
  deployer.link(StemCreation, StemRootchain);
  
  // 1. Operator not enough error
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", [], [], {value: 8234567890});
  
  // 2. number of operator and number of deposits not match error
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890"], {value: 8234567890});

  // 3. Repeated operator error
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890", "1234567890"], {value: 8234567890});
  
  // 4. creator deposit not enough error
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "100", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {value: 8234567890});

  // 5. Insufficient total deposit value
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {value: 1234567890});

  // 6. Insufficient (individual) operator deposit value
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["10", "1234567890", "1234567890", "1234567890"], {value: 1234567890});

  // 7. Invalid operator address
  // deployer.deploy(StemRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0x000000000000000000000000000000000000000", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {value: 1234567890});
  
  deployer.deploy(StemRootchain, "416e6e6965", ["0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823"], ["107.105.20.39"], "1000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], {from: accounts[2], value: 8234567890, gas:6500000});
  
  deployer.link(RLPEncoding, SandboxStemRootchain)
  deployer.link(StemCore, SandboxStemRootchain);
  deployer.link(StemChallenge, SandboxStemRootchain);
  deployer.link(StemRelay, SandboxStemRootchain);
  deployer.link(StemCreation, SandboxStemRootchain);
  deployer.deploy(SandboxStemRootchain, "416e6e6965", ["0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823"], ["107.105.20.39"], "1000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], {from: accounts[2], value: 8234567890, gas:6500000});  
};

//"0x416e6e6965", ["0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823"], ["0x1071052039"], "1", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["3", "3", "3", "3"], ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x627306090abab3a6e1400e9345bc60c78a8bef57", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"]
