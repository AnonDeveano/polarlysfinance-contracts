const Storage = artifacts.require("Storage");
const Borealis = artifacts.require("Borealis");
const Distributor = artifacts.require("Distributor");
const DummyToken = artifacts.require("DummyToken");
const Nebula = artifacts.require("Nebula");
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
var WarpDrive = artifacts.require("NebulaGenesisRewardPool");
var WarpDrive = artifacts.require("distribution/NebulaRewardPool");

module.exports = function (deployer) {
    // Deployer is the Truffle wrapper for deploying
    // contracts to the network

    // Deploy the contract to the network
    deployer.deploy(Storage);
    deployer.deploy(Borealis);
    deployer.deploy(Distributor);
    deployer.deploy(DummyToken);
    deployer.deploy(Nebula);
    deployer.deploy(Oracle);
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