var Storage = artifacts.require("Storage");
var Nebula = artifacts.require("Nebula");
var Borealis = artifacts.require("Borealis");
var StarDust = artifacts.require("StarDust");
var MockedNebula = artifacts.require("MockedNebula");
var MockedBorealis = artifacts.require("MockedBorealis");

module.exports = async (deployer, network, [account]) => {
    //
    let time = "0";

    const devFund = "0x7299192CD862c9c5345cC47a2Ef24807436009b0";
    const communityFund = "0x86A247546cA84735542bF61BEE722b0250bDFfc9";
    const teamFund = "0x5A7a3609474790cb6399b5F0422967e995037A1d";

    const nebulaContract = network == 'mainnet' ? Nebula : MockedNebula;
    const borealisContract = network == 'mainnet' ? Borealis : MockedBorealis;

    await deployer.deploy(Storage);
    await deployer.deploy(nebulaContract);
    await deployer.deploy(borealisContract, time, communityFund, devFund, teamFund);
    await deployer.deploy(StarDust);
};
