var Storage = artifacts.require("Storage");
var Borealis = artifacts.require("Borealis");
var Distributor = artifacts.require("Distributor");
var DummyToken = artifacts.require("DummyToken");
var Nebula = artifacts.require("Nebula");
var Oracle = artifacts.require("Oracle");
var SimpleERCFund = artifacts.require("SimpleERCFund");
var StarDust = artifacts.require("StarDust");
var TaxOffice = artifacts.require("TaxOffice");
var TaxOfficeV2 = artifacts.require("TaxOfficeV2");
var TaxOracle = artifacts.require("TaxOracle");
var Timelock = artifacts.require("Timelock");
var Treasury = artifacts.require("Treasury");
var WarpDrive = artifacts.require("WarpDrive");
var BorealisRewardPool = artifacts.require("BorealisRewardPool");
var NebulaGenesisRewardPool = artifacts.require("NebulaGenesisRewardPool");
var NebulaRewardPool = artifacts.require("distribution/NebulaRewardPool");

module.exports = function (deployer) {
    // Deployer is the Truffle wrapper for deploying
    // contracts to the network

    uint256 _startTime = //;
    const accounts = await web3.eth.getAccounts();
    const _devFund = accounts[0];
    const _communityFund = accounts[1];
    const _teamFund = accounts[2];

    // Deploy the contract to the network
    deployer.deploy(Storage);
    deployer.deploy(Borealis, _communityFund, _devFund, _teamFund);
    deployer.deploy(Distributor);
    deployer.deploy(DummyToken);
    deployer.deploy(Nebula);
    deployer.deploy(Oracle); //
    deployer.deploy(SimpleERCFund);
    deployer.deploy(StarDust);
    deployer.deploy(TaxOffice);
    deployer.deploy(TaxOfficeV2);
    deployer.deploy(TaxOracle);
    deployer.deploy(Timelock);
    deployer.deploy(Treasury);
    deployer.deploy(WarpDrive);
    deployer.deploy(BorealisRewardPool);
    deployer.deploy(NebulaGenesisRewardPool)
    deployer.deploy(NebulaRewardPool);
};