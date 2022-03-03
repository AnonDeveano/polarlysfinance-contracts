var Nebula = artifacts.require("Nebula");
var Borealis = artifacts.require("Borealis");
var MockedNebula = artifacts.require("MockedNebula");
var MockedBorealis = artifacts.require("MockedBorealis");
var MockedWNear = artifacts.require("MockedWNear");
var IWrappedNear = artifacts.require("IWrappedNear");
var Router = artifacts.require("IUniswapV2Router");
var Factory = artifacts.require("IUniswapV2Factory");

// From my understanding, this sets up the testnet to create an LP pool automatically
// This is defined above module.exports and later called only in the testnet part below
async function addLiquidity(t0, t1, router, t1Multiplier, to) {
    const AMOUNT = '100000000000000000000000000000';
    const T1AMOUNT = (BigInt(AMOUNT) * BigInt(t1Multiplier)).toString();
    const TIMESTAMP = await web3.eth.getBlock('latest').then(
        (r) => (BigInt(r.timestamp) + 10000000n).toString());
    await t0.mint(AMOUNT);
    await t1.mint(T1AMOUNT);
    await t0.approve(router.address, AMOUNT);
    await t1.approve(router.address, T1AMOUNT);

    // addLiq(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline)    
    await router.addLiquidity(token0.address, token1.address, AMOUNT, T1AMOUNT, 1, 1, to, TIMESTAMP);
}

async function showPairs(factory, nebula, borealis, wnear) {
    await factory.getPair(nebula, wnear).then(res => console.log("NEBULA PAIR: ", res));
    await factory.getPair(borealis, wnear).then(res => console.log("BOREALIS PAIR: ", res));
}

module.exports = async (deployer, network, [account]) {
    let factory;
    let nebula;
    let borealis;
    let wnear;
    if (network == 'testnet') {
        const router = "0x0000000000000000000000000000000000000000";
        const nebula_price = 1;
        const borealis_price = 3;
        await deployer.deploy(MockedWNear);
        wnear = await MockedWNear.deployed();
        nebula = await MockedNebula.deployed();
        borealis = await MockedBorealis.deployed();
        const router = await Router.at(ROUTER);
        const FACTORY = await router.factory();
        factory = await Factory.at(FACTORY);
        await addLiquidity(nebula, wnear, router, nebula_price, account);
        await addLiquidity(borealis, wnear, router, borealis_price, account);
    } else if (network == 'mainnet') {
        const nebula = '';
        const borealis = '';
        const wnear = '';
        const FACTORY = '';
        nebula = await Nebula.at(Nebula);
        borealis = await Borealis.at(Borealis);
        wnear = await IWrappedNear.at(WNEAR)
        factory = await Factory.at(FACTORY);
    }
    await showPairs(factory, nebula.address, borealis.address, wnear.address);
};