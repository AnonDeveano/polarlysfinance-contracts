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

    // this is the local contract address of Nebula.sol, just testing deployments
    // so this is NOT a valid pair
    const _pair = "0x9dECB539Ac4B4DE5984d8f555907fAF17c57272d";
    // local contract address of Borealis/Stardust just so it can be tested in TaxOfficeV2
    const _base = "0xd103Ed8CE77d003B9f203183dB2490eC7384e855";
    const _router = "0x641FB670D5328B2c5c294Eef8A40c0676ED6fd4c";

    let _distributors = [];

    // Deploy the contract to the network
    deployer.deploy(Storage);
    deployer.deploy(Borealis, time, _communityFund, _devFund, _teamFund);
    deployer.deploy(Distributor, _distributors);
    deployer.deploy(DummyToken);
    deployer.deploy(Nebula);
    deployer.deploy(SimpleERCFund);
    deployer.deploy(StarDust);
    deployer.deploy(TaxOffice, _pair); //
    deployer.deploy(TaxOfficeV2, _pair, _base, _router);
    deployer.deploy(TaxOracle, _pair, _base, _router);
    deployer.deploy(Timelock, _devFund, delay);
    deployer.deploy(Treasury);
    deployer.deploy(WarpDrive);
    // using other vars from above just to test deployment
    deployer.deploy(BorealisRewardPool, _base, time);
    deployer.deploy(NebulaGenesisRewardPool, _pair, _router, time);
    deployer.deploy(NebulaRewardPool, _pair, time);
    // moved to the end of this deploy stack since require statement is reverting 
    // due to no locked liq for this test
    deployer.deploy(Oracle, _pair, _period, time);
};