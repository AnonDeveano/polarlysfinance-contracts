const NebulaRewardPool = artifacts.require('NebulaRewardPool');
const BorealisRewardPool = artifacts.require('BorealisRewardPool');
const Nebula = artifacts.require('Nebula');
const Borealis = artifacts.require('Borealis');


module.exports = async (deployer) => {
    const nebula = Nebula.deployed();
    const borealis = Borealis.deployed();
    const poolStartTime = '0';

    await deployer.deploy(NebulaRewardPool, nebula, poolStartTime);
    await deployer.deploy(BorealisRewardPool, borealis, poolStartTime);
}
