const NebulaGenesisRewardPool = artifacts.require('NebulaGenesisRewardPool');
const MockedCommissionToken = artifacts.require('MockedCommissionToken');

module.exports = async (deployer, network) => {
    const Nebula = '';
    const daoFund = '';
    let commissionTokens = [];
    const _poolStartTime = '0';

    if (network == 'testnet') {
        await deployer.deploy(MockedCommissionToken);
        await MockedCommissionToken.deployed().then(res => commissionTokens.push(res.address));
    }

    await deployer.deploy(NebulaGenesisRewardPool, Nebula, daoFund, _poolStartTime);
}