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

    let time = Date.now();
    // 6 hrs
    let _period = 3600 * 6;
    // 5 days test delay just for deployment
    let delay = 86400 * 5;

    const _devFund = "0x7299192CD862c9c5345cC47a2Ef24807436009b0";
    const _communityFund = "0x86A247546cA84735542bF61BEE722b0250bDFfc9";
    const _teamFund = "0x5A7a3609474790cb6399b5F0422967e995037A1d";
    const admin_ = "0x7299192CD862c9c5345cC47a2Ef24807436009b0";

    // define these explicitly as required for TaxOfficeV2
    const _pair = "";
    const _base = "";
    const _router = "";

    // nebula testnet address
    const _nebula = "";
    // boralis testnet address
    const _borealis = "";
    // required for contracts under distributions/
    const poolStartTime = "";

    let _distributors = [];

    // Deploy the contract to the network
    deployer.deploy(Storage);
    deployer.deploy(Borealis, time, _communityFund, _devFund, _teamFund);
    deployer.deploy(Distributor, _distributors);
    deployer.deploy(DummyToken);
    deployer.deploy(Nebula);
    deployer.deploy(SimpleERCFund);
    deployer.deploy(StarDust);
    // requires Nebula address
    deployer.deploy(TaxOffice);
    // requires Nebula address, base, and router. WHAT IS BASE AND ROUTER explicitly?
    deployer.deploy(TaxOfficeV2);
    // requires Nebula, near, and pair in constructor but contains functions to set later
    deployer.deploy(TaxOracle);
    deployer.deploy(Timelock, admin_, delay);
    // Does this need to be deployed with params?
    deployer.deploy(Treasury);
    deployer.deploy(WarpDrive);
    // requires Borealis var and Pool start time
    deployer.deploy(BorealisRewardPool);
    // what is the shiba const referring to?
    // requires nebula address, shiba address, and can use same pool start time as Borealis
    deployer.deploy(NebulaGenesisRewardPool);
    // requires Nebula address and pool start time
    deployer.deploy(NebulaRewardPool);
    // requires pair, period, start params
    deployer.deploy(Oracle);
};