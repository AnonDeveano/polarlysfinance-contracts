const TaxOracle = artifacts.require('TaxOracle');
const Oracle = artifacts.require('Oracle');
const TaxOfficeV2 = artifacts.require('TaxOfficeV2');
const WarpDrive = artifacts.require('WarpDrive');
const Treasury = artifacts.require('Treasury');

module.exports = async (deployer) => {
    const nebula = "0xF1FA1E50418c2B4c6ea8669101053Ddb304E9e1e";

    // this might fail with require statement that nebula_pair =/= 0
    const nebula_pair = "0x0000000000000000000000000000000000000000";

    const wnear = "0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d";

    const router = '0x0000000000000000000000000000000000000000';

    const oracle_start_time = '0';

    // TaxOracle, can set Nebula, wnear, and pair after
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