// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IWarpDrive.sol";

/*

Polarlys Finance

*/
contract Treasury is ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 6 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // core components
    address public nebula;
    address public stardust;
    address public borealis;

    address public warpdrive;
    address public nebulaOracle;

    // price
    uint256 public nebulaPriceOne;
    uint256 public nebulaPriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    // 28 first epochs (1 week) with 4.5% expansion regardless of NEBULA price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochNebulaPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra NEBULA during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;
    address public teamFund;
    uint256 public teamFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 nebulaAmount, uint256 bondAmount);
    event BoughtstarDusts(address indexed from, uint256 nebulaAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event WarpDriveFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition() {
        require(now >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(now >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getNebulaPrice() > nebulaPriceCeiling) ? 0 : getNebulaCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(nebula).operator() == address(this) &&
                IBasisAsset(stardust).operator() == address(this) &&
                IBasisAsset(borealis).operator() == address(this) &&
                Operator(warpdrive).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getNebulaPrice() public view returns (uint256 nebulaPrice) {
        try IOracle(nebulaOracle).consult(nebula, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult NEBULA price from the oracle");
        }
    }

    function getNebulaUpdatedPrice() public view returns (uint256 _nebulaPrice) {
        try IOracle(nebulaOracle).twap(nebula, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult NEBULA price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnableNebulaLeft() public view returns (uint256 _burnableNebulaLeft) {
        uint256 _nebulaPrice = getNebulaPrice();
        if (_nebulaPrice <= nebulaPriceOne) {
            uint256 _nebulaSupply = getNebulaCirculatingSupply();
            uint256 _bondMaxSupply = _nebulaSupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(stardust).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableNebula = _maxMintableBond.mul(_nebulaPrice).div(1e18);
                _burnableNebulaLeft = Math.min(epochSupplyContractionLeft, _maxBurnableNebula);
            }
        }
    }

    function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
        uint256 _nebulaPrice = getNebulaPrice();
        if (_nebulaPrice > nebulaPriceCeiling) {
            uint256 _totalNebula = IERC20(nebula).balanceOf(address(this));
            uint256 _rate = getstarDustPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalNebula.mul(1e18).div(_rate);
            }
        }
    }

    function getstarDustDiscountRate() public view returns (uint256 _rate) {
        uint256 _nebulaPrice = getNebulaPrice();
        if (_nebulaPrice <= nebulaPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = nebulaPriceOne;
            } else {
                uint256 _bondAmount = nebulaPriceOne.mul(1e18).div(_nebulaPrice); // to burn 1 NEBULA
                uint256 _discountAmount = _bondAmount.sub(nebulaPriceOne).mul(discountPercent).div(10000);
                _rate = nebulaPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getstarDustPremiumRate() public view returns (uint256 _rate) {
        uint256 _nebulaPrice = getNebulaPrice();
        if (_nebulaPrice > nebulaPriceCeiling) {
            uint256 _nebulaPricePremiumThreshold = nebulaPriceOne.mul(premiumThreshold).div(100);
            if (_nebulaPrice >= _nebulaPricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _nebulaPrice.sub(nebulaPriceOne).mul(premiumPercent).div(10000);
                _rate = nebulaPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = nebulaPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _nebula,
        address _stardust,
        address _borealis,
        address _nebulaOracle,
        address _warpdrive,
        uint256 _startTime
    ) public notInitialized {
        nebula = _nebula;
        stardust = _stardust
        borealis = _borealis;
        nebulaOracle = _nebulaOracle;
        warpdrive = _warpdrive;
        startTime = _startTime;

        nebulaPriceOne = 10**18;
        nebulaPriceCeiling = nebulaPriceOne.mul(101).div(100);

        // ANALYZE THIS // 
        // Dynamic max expansion percent
        supplyTiers = [0 ether, 500000 ether, 1000000 ether, 1500000 ether, 2000000 ether, 5000000 ether, 10000000 ether, 20000000 ether, 50000000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for warpdrive
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn NEBULA and mint STARDUST)
        maxDebtRatioPercent = 3500; // Upto 35% supply of STARDUST to purchase

        premiumThreshold = 110;
        premiumPercent = 7000;

        // Check bootstrapEpochs
        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 28;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(nebula).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setWarpDrive(address _warpdrive) external onlyOperator {
        warpdrive = _warpdrive;
    }

    function setNebulaOracle(address _nebulaOracle) external onlyOperator {
        nebulaOracle = _nebulaOracle;
    }

    function setNebulaPriceCeiling(uint256 _nebulaPriceCeiling) external onlyOperator {
        require(_nebulaPriceCeiling >= nebulaPriceOne && _nebulaPriceCeiling <= nebulaPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        nebulaPriceCeiling = _nebulaPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function sestarDustDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent,
        address _teamFund,
        uint256 _teamFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3000, "out of range"); // <= 30%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 500, "out of range"); // <= 5%
        require(_teamFund != address(0), "zero");
        require(_teamFundSharedPercent <= 500, "out of range");  // <= 5%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
        teamFund = _teamFund;
        teamFundSharedPercent = _teamFundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= nebulaPriceCeiling, "_premiumThreshold exceeds nebulaPriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateNebulaPrice() internal {
        try IOracle(nebulaOracle).update() {} catch {}
    }

    function getNebulaCirculatingSupply() public view returns (uint256) {
        IERC20 nebulaErc20 = IERC20(nebula);
        uint256 totalSupply = nebulaErc20.totalSupply();
        uint256 balanceExcluded = 0;
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _nebulaAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_nebulaAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 nebulaPrice = getNebulaPrice();
        require(nebulaPrice == targetPrice, "Treasury: NEBULA price moved");
        require(
            nebulaPrice < nebulaPriceOne, // price < $1
            "Treasury: nebulaPrice not eligible for bond purchase"
        );

        require(_nebulaAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint256 _rate = getstarDustDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _nebulaAmount.mul(_rate).div(1e18);
        uint256 nebulaSupply = getNebulaCirculatingSupply();
        uint256 newBondSupply = IERC20(stardust).totalSupply().add(_bondAmount);
        require(newBondSupply <= nebulaSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(nebula).burnFrom(msg.sender, _nebulaAmount);
        IBasisAsset(stardust).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_nebulaAmount);
        _updateNebulaPrice();

        emit BoughtstarDusts(msg.sender, _nebulaAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 nebulaPrice = getNebulaPrice();
        require(nebulaPrice == targetPrice, "Treasury: NEBULA price moved");
        require(
            nebulaPrice > nebulaPriceCeiling, // price > $1.01
            "Treasury: nebulaPrice not eligible for bond purchase"
        );

        uint256 _rate = getstarDustPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _nebulaAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(nebula).balanceOf(address(this)) >= _nebulaAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _nebulaAmount));

        IBasisAsset(stardust).burnFrom(msg.sender, _bondAmount);
        IERC20(nebula).safeTransfer(msg.sender, _nebulaAmount);

        _updateNebulaPrice();

        emit RedeemedBonds(msg.sender, _nebulaAmount, _bondAmount);
    }

    function _sendToWarpDrive(uint256 _amount) internal {
        IBasisAsset(nebula).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(nebula).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(now, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(nebula).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(now, _devFundSharedAmount);
        }

        uint256 _teamFundSharedAmount = 0;
        if (teamFundSharedPercent > 0) {
            _teamFundSharedAmount = _amount.mul(teamFundSharedPercent).div(10000);
            IERC20(nebula).transfer(teamFund, _teamFundSharedAmount);
            emit TeamFundFunded(now, _teamFundSharedAmount);
        }


        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount).sub(_teamFundSharedAmount);

        IERC20(nebula).safeApprove(warpdrive, 0);
        IERC20(nebula).safeApprove(warpdrive, _amount);
        IWarpDrive(warpdrive).allocateSeigniorage(_amount);
        emit WarpDriveFunded(now, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _nebulaSupply) internal returns (uint256) {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_nebulaSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateNebulaPrice();
        previousEpochNebulaPrice = getNebulaPrice();
        uint256 nebulaSupply = getNebulaCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            _sendToWarpDrive(nebulaSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochNebulaPrice > nebulaPriceCeiling) {
                // Expansion ($NEBULA Price > 1 $NEAR): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(stardust).totalSupply();
                uint256 _percentage = previousEpochNebulaPrice.sub(nebulaPriceOne);
                uint256 _savedForBond;
                uint256 _savedForWarpDrive;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(nebulaSupply).mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForWarpDrive = nebulaSupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = nebulaSupply.mul(_percentage).div(1e18);
                    _savedForWarpDrive = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForWarpDrive);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForWarpDrive > 0) {
                    _sendToWarpDrive(_savedForWarpDrive);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(nebula).mint(address(this), _savedForBond);
                    emit TreasuryFunded(now, _savedForBond);
                }
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(nebula), "nebula");
        require(address(_token) != address(stardust), "stardust");
        require(address(_token) != address(borealis), "borealis");
        _token.safeTransfer(_to, _amount);
    }

    function warpdriveSetOperator(address _operator) external onlyOperator {
        IWarpDrive(warpdrive).setOperator(_operator);
    }

    function warpdriveSetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IWarpDrive(warpdrive).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function warpdriveAllocateSeigniorage(uint256 amount) external onlyOperator {
        IWarpDrive(warpdrive).allocateSeigniorage(amount);
    }

    function warpdriveGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IWarpDrive(warpdrive).governanceRecoverUnsupported(_token, _amount, _to);
    }
}
