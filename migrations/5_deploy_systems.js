const TaxOracle = artifacts.require('TaxOracle');
const TaxOfficeV2 = artifacts.require('TaxOfficeV2');

module.exports = async (deployer) => {
    const nebula = "0xF1FA1E50418c2B4c6ea8669101053Ddb304E9e1e";

    // LP added on Aries testnet
    const nebula_pair = "0x9F175EFB10915dFc523c6ce36593301A2e408be7";

    const wnear = "0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d";

    // Personal address used just to deploy
    const router = '0x7299192CD862c9c5345cC47a2Ef24807436009b0';

    const PERIOD = 2600;

    // TaxOracle, can set Nebula, wnear, and pair after
    await deployer.deploy(TaxOracle, nebula, wnear, nebula_pair);


    // TaxOfficeV2
    await deployer.deploy(TaxOfficeV2, nebula, wnear, router);

    // WarpDrive
    await deployer.deploy(WarpDrive);
}