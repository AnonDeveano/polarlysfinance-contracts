const TaxOracle = artifacts.require('TaxOracle');
const Oracle = artifacts.require('Oracle');
const TaxOfficeV2 = artifacts.require('TaxOfficeV2');
const WarpDrive = artifacts.require('WarpDrive');
const Treasury = artifacts.require('Treasury');
const TaxOracle = artifacts.require('TaxOracle');

module.exports = async (deployer) => {
    const nebula = '';
    const borealis = '';
    const nebula_pair = '';
    const wnear = '';
    const router = '0x0000000000000000000000000000000000000000';
    const oracle_start_time = '0';

    // TaxOracle
    await deployer.deploy(TaxOracle, nebula, wnear, nebula_pair);

    // Treasury
    await deployer.deploy(Treasury);
    const treasury = await Treasury.deployed();
    const PERIOD = await treasury.PERIOD();

    // Oracle
    await deployer.deploy(Oracle, nebula_pair, PERIOD, oracle_start_time);

    // WarpDrive
    await deployer.deploy(WarpDrive);

    // TaxOfficeV2
    await deployer.deploy(TaxOfficeV2, nebula, router);
}