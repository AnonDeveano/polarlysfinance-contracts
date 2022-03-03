const NebulaRewardPool = artifacts.require('NebulaRewardPool');

module.exports = async (deployer) => {
    const nebula = '';
    const poolStartTime = '0';

    await deployer.deploy(NebulaRewardPool, nebula, poolStartTime);
}