var Storage = artifacts.require("Storage");
var Nebula = artifacts.require("Nebula");
var Borealis = artifacts.require("Borealis");
var StarDust = artifacts.require("StarDust");

module.exports = async (deployer) => {
    //
    let time = "0";

    const devFund = "0x7299192CD862c9c5345cC47a2Ef24807436009b0";
    const communityFund = "0x86A247546cA84735542bF61BEE722b0250bDFfc9";
    const teamFund = "0x5A7a3609474790cb6399b5F0422967e995037A1d";

    await deployer.deploy(Storage);
    await deployer.deploy(Nebula);
    await deployer.deploy(Borealis, time, communityFund, devFund, teamFund);
    await deployer.deploy(StarDust);
};
