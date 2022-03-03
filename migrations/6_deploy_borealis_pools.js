const BorealisRewardPool = artifacts.require('BorealisRewardPool');

module.exports = async (deployer) => {
    const borealis = '';
    const poolStartTime = '0';

    await deployer.deploy(BorealisRewardPool, borealis, poolStartTime);
}