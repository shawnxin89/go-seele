var ECRecovery = artifacts.require("./ECRecovery.sol");
var PriorityQueue = artifacts.require("./PriorityQueue.sol");
var MultipleOperatorRootchain = artifacts.require("./MultipleOperatorRootchain.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(ECRecovery);
  deployer.deploy(PriorityQueue);
  deployer.link(ECRecovery, MultipleOperatorRootchain);
  deployer.link(PriorityQueue, MultipleOperatorRootchain);
  
  // 1. Operator not enough error
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", [], [], {value: 8234567890});
  
  // 2. number of operator and number of deposits not match error
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890"], {value: 8234567890});

  // 3. Repeated operator error
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890", "1234567890"], {value: 8234567890});
  
  // 4. creatro deposit not enough error
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "100", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {value: 8234567890});

  // 5. Insufficient total operator deposit value
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {value: 1234567890});

  // 6. Insufficient (individual) operator deposit value
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["10", "1234567890", "1234567890", "1234567890"], {value: 1234567890});

  // 7. Invalid operator address
  // deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0x000000000000000000000000000000000000000", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {value: 1234567890});
  
  deployer.deploy(MultipleOperatorRootchain, "416e6e6965", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", "0x4f2df4a21621b18c71619239c398657a23f198a40a8deff701e340e6e34d0823", ["107.105.20.39"], "1000000", ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "0x583031d1113ad414f02576bd6afabfb302140225"], ["1234567890", "1234567890", "1234567890", "1234567890"], {from: accounts[2], value: 8234567890});
};
