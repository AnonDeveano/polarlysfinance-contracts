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

    const _devFund = "0x7299192CD862c9c5345cC47a2Ef24807436009b0";
    const _communityFund = "0x86A247546cA84735542bF61BEE722b0250bDFfc9";
    const _teamFund = "0x5A7a3609474790cb6399b5F0422967e995037A1d";


    // Used for 'gatekeeper tax' previously, has been deprecated
    // after it was exploited
    const _zeroaddy = "0x0000000000000000000000000000000000000000";
    const _pair = _zeroaddy;
    const _base = _zeroaddy;
    const _router = _zeroaddy;

    // nebula testnet address
    const _nebula = "";
    // borealis testnet address
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
    deployer.deploy(TaxOfficeV2, _zeroaddy, _base, _router);
    deployer.deploy(TaxOracle, _zeroaddy, _zeroaddy, _zeroaddy);
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