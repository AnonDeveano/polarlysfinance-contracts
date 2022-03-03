const Nebula = artifacts.require('Nebula');
const Borealis = artifacts.require('Borealis');
const StarDust = artifacts.require('StarDust');
const TaxOracle = artifacts.require('TaxOracle');
const Oracle = artifacts.require('Oracle');
const TaxOfficeV2 = artifacts.require('TaxOfficeV2');
const WarpDrive = artifacts.require('WarpDrive');
const Treasury = artifacts.require('Treasury');

module.exports = async (deployer) => {
    const devFund = "0x7299192CD862c9c5345cC47a2Ef24807436009b0";
    const communityFund = "0x86A247546cA84735542bF61BEE722b0250bDFfc9";
    const teamFund = "0x5A7a3609474790cb6399b5F0422967e995037A1d";

    const NEBULA = '';
    const BOREALIS = '';
    const STARDUST = '';
    const treasury_start_time = '0';

    const community_fund_shared_percent = 2000;
    const dev_fund_shared_percent = 750;
    const team_fund_shared_percent = 500;

    const nebula = await Nebula.at(NEBULA);
    const borealis = await Borealis.at(BOREALIS);
    const stardust = await StarDust.at(StarDust);
    const taxOracle = await TaxOracle.deployed();
    const oracle = await Oracle.deployed();
    const treasury = await Treasury.deployed();
    const warpDrive = await WarpDrive.deployed();
    const taxOfficeV2 = await TaxOfficeV2.deployed();

    // Treasury initialize 
    // function initialize(address _nebula, address _stardust, address _borealis, address _nebulaOracle, address _warpdrive, uint256 _startTime
    await treasury.initialize(NEBULA, STARDUST, BOREALIS, oracle.address, warpDrive.address, treasury_start_time);

    // Warp Drive initialize
    await warpDrive.initialize(NEBULA, BOREALIS, treasury.address);

    // Oracle update 
    await oracle.update();

    // Treasury setExtraFunds
    await treasury.setExtraFunds(communityFund, community_fund_shared_percent, devFund, dev_fund_shared_percent, teamFund, team_fund_shared_percent);

    // Nebula setNebulaOracle
    await nebula.setNebulaOracle(taxOracle.address);

    // Nebula setTaxOffice
    await nebula.setTaxOffice(taxOfficeV2.address);

    // [Nebula, Borealis, StarDust, Oracle] transfer operator
    for (let contract of [nebula, borealis, stardust, oracle]) {
        await contract.transferOperator(treasury.address);
    }

    // WarpDrive setOperator
    await warpDrive.setOperator(treasury.address);
}