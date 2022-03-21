const NebulaGenesisRewardPool = artifacts.require('NebulaGenesisRewardPool');
const MockedCommissionToken = artifacts.require('MockedCommissionToken');
const Nebula = artifacts.require('Nebula');

module.exports = async (deployer, network) => {
    const Nebula = Nebula.deployed();
    const daoFund = '0x86A247546cA84735542bF61BEE722b0250bDFfc9';
    let commissionTokens = [];
    const _poolStartTime = '0';

    if (network == 'testnet') {
        await deployer.deploy(MockedCommissionToken);
        await MockedCommissionToken.deployed().then(res => commissionTokens.push(res.address));
    }

    await deployer.deploy(NebulaGenesisRewardPool, Nebula, daoFund, _poolStartTime);
}