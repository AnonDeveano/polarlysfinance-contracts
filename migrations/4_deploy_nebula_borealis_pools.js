const NebulaRewardPool = artifacts.require('NebulaRewardPool');
const BorealisRewardPool = artifacts.require('BorealisRewardPool');
const Nebula = artifacts.require('Nebula');
const Borealis = artifacts.require('Borealis');


module.exports = async (deployer) => {
    const Nebula = '0x2dEC88f821f4a84C19Aee910E00DB750Bbc6455D';
    const Borealis = '0x3eeCecb9853b1eC447c44CEfF7B9d68993AeA565';
    const poolStartTime = 1659069176;

    await deployer.deploy(NebulaRewardPool, Nebula, poolStartTime);
    await deployer.deploy(BorealisRewardPool, Borealis, poolStartTime);
}
