const NebulaGenesisRewardPool = artifacts.require('NebulaGenesisRewardPool');
const Nebula = artifacts.require('Nebula');

module.exports = async (deployer) => {
    const Nebula = '0x2dEC88f821f4a84C19Aee910E00DB750Bbc6455D';
    const _poolStartTime = 1659069176;
    // 1645106400
    // 1649069176

    await deployer.deploy(NebulaGenesisRewardPool, Nebula, _poolStartTime);
}