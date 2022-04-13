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

    const NEBULA = "0xF1FA1E50418c2B4c6ea8669101053Ddb304E9e1e";
    const BOREALIS = "0x35dc838ccFe7A5a67Fba5e4749fc6aB531A1334E";
    const STARDUST = "0xEcd52e6395B0359ACa1fd0D44B6F20AB10837d6E";
    const treasury_start_time = 1649170000;

    const community_fund_shared_percent = 2000;
    const dev_fund_shared_percent = 750;
    const team_fund_shared_percent = 500;

    // const WarpDrive = "0x63F29341Dd64bB81D267A853fF75b1CA10477A94";
    // const TaxOracle = "0xaE5659B0734B291446b07a1B2E56a6324971aB8E";
    // const Oracle = "0x5516B361d83cdB8368f3258d792123E1dd8DB328";
    // const TaxOfficeV2 = "0x4A5DE7093d438fC16F3BF886B56A69f5B5eb8a3D";
    // const treasury = "0x5E234f4b175A1C7DF9076999DAB63bd81B9fF616";

    const nebula = await Nebula.at(NEBULA);
    const borealis = await Borealis.at(BOREALIS);
    const stardust = await StarDust.at(STARDUST);
    const taxOracle = await TaxOracle.deployed();
    const oracle = await Oracle.deployed();
    const treasury = await Treasury.deployed();
    const taxOfficeV2 = await TaxOfficeV2.deployed();
    const warpDrive = await WarpDrive.deployed();

    await treasury.initialize(NEBULA, STARDUST, BOREALIS, oracle.address, warpDrive.address, treasury_start_time);

    await warpDrive.initialize(NEBULA, BOREALIS, treasury.address);

    await oracle.update();

    await treasury.setExtraFunds(communityFund, community_fund_shared_percent, devFund, dev_fund_shared_percent, teamFund, team_fund_shared_percent);

    await nebula.setNebulaOracle(taxOracle.address);

    await nebula.setTaxOffice(taxOfficeV2.address);

    for (let contract of [nebula, borealis, stardust, oracle]) {
        await contract.transferOperator(treasury.address);
    }

    await warpDrive.setOperator(treasury.address);


}