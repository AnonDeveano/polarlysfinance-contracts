// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./owner/Operator.sol";
import "./interfaces/ITaxable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC20.sol";

/*

Polarlys Finance

*/
contract TaxOfficeV2 is Operator {
    using SafeMath for uint256;

    address public nebula;
    address public base;
    address public router;

    mapping(address => bool) public taxExclusionEnabled;

    constructor(
        address _nebula,
        address _base,
        address _router
    ) public {
        require(_nebula != address(0), "Address cannot be 0");
        nebula = _nebula;

        require(_base != address(0), "Address cannot be 0");
        base = _base;

        require(_router != address(0), "Address cannot be 0");
        router = _router;
    }

    function setTaxTiersTwap(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(nebula).setTaxTiersTwap(_index, _value);
    }

    function setTaxTiersRate(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(nebula).setTaxTiersRate(_index, _value);
    }

    function enableAutoCalculateTax() public onlyOperator {
        ITaxable(nebula).enableAutoCalculateTax();
    }

    function disableAutoCalculateTax() public onlyOperator {
        ITaxable(nebula).disableAutoCalculateTax();
    }

    function setTaxRate(uint256 _taxRate) public onlyOperator {
        ITaxable(nebula).setTaxRate(_taxRate);
    }

    function setBurnThreshold(uint256 _burnThreshold) public onlyOperator {
        ITaxable(nebula).setBurnThreshold(_burnThreshold);
    }

    function setTaxCollectorAddress(address _taxCollectorAddress) public onlyOperator {
        ITaxable(nebula).setTaxCollectorAddress(_taxCollectorAddress);
    }

    function excludeAddressFromTax(address _address) external onlyOperator returns (bool) {
        return _excludeAddressFromTax(_address);
    }

    function _excludeAddressFromTax(address _address) private returns (bool) {
        if (!ITaxable(nebula).isAddressExcluded(_address)) {
            return ITaxable(nebula).excludeAddress(_address);
        }
    }

    function includeAddressInTax(address _address) external onlyOperator returns (bool) {
        return _includeAddressInTax(_address);
    }

    function _includeAddressInTax(address _address) private returns (bool) {
        if (ITaxable(nebula).isAddressExcluded(_address)) {
            return ITaxable(nebula).includeAddress(_address);
        }
    }

    function taxRate() external returns (uint256) {
        return ITaxable(nebula).taxRate();
    }

    function addLiquidityTaxFree(
        address token,
        uint256 amtNebula,
        uint256 amtToken,
        uint256 amtNebulaMin,
        uint256 amtTokenMin
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtNebula != 0 && amtToken != 0, "amounts can't be 0");
        _excludeAddressFromTax(msg.sender);

        IERC20(nebula).transferFrom(msg.sender, address(this), amtNebula);
        IERC20(token).transferFrom(msg.sender, address(this), amtToken);
        _approveTokenIfNeeded(nebula, router);
        _approveTokenIfNeeded(token, router);

        _includeAddressInTax(msg.sender);

        uint256 resultAmtNebula;
        uint256 resultAmtToken;
        uint256 liquidity;
        (resultAmtNebula, resultAmtToken, liquidity) = IUniswapV2Router(router).addLiquidity(
            nebula,
            token,
            amtNebula,
            amtToken,
            amtNebulaMin,
            amtTokenMin,
            msg.sender,
            block.timestamp
        );

        if (amtNebula.sub(resultAmtNebula) > 0) {
            IERC20(nebula).transfer(msg.sender, amtNebula.sub(resultAmtNebula));
        }
        if (amtToken.sub(resultAmtToken) > 0) {
            IERC20(token).transfer(msg.sender, amtToken.sub(resultAmtToken));
        }
        return (resultAmtNebula, resultAmtToken, liquidity);
    }

    function addLiquidityETHTaxFree(
        uint256 amtNebula,
        uint256 amtNebulaMin,
        uint256 amtEthMin
    )
        external
        payable
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtNebula != 0 && msg.value != 0, "amounts can't be 0");
        _excludeAddressFromTax(msg.sender);

        IERC20(nebula).transferFrom(msg.sender, address(this), amtNebula);
        _approveTokenIfNeeded(nebula, router);

        _includeAddressInTax(msg.sender);

        uint256 resultAmtNebula;
        uint256 resultAmtEth;
        uint256 liquidity;
        (resultAmtNebula, resultAmtEth, liquidity) = IUniswapV2Router(router).addLiquidityETH{value: msg.value}(
            nebula,
            amtNebula,
            amtNebulaMin,
            amtEthMin,
            msg.sender,
            block.timestamp
        );

        if (amtNebula.sub(resultAmtNebula) > 0) {
            IERC20(nebula).transfer(msg.sender, amtNebula.sub(resultAmtNebula));
        }
        return (resultAmtNebula, resultAmtEth, liquidity);
    }

    function setTaxableNebulaOracle(address _NebOracle) external onlyOperator {
        ITaxable(nebula).setNebulaOracle(_NebOracle);
    }

    function transferTaxOffice(address _newTaxOffice) external onlyOperator {
        ITaxable(nebula).setTaxOffice(_newTaxOffice);
    }

    function taxFreeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amt
    ) external {
        require(taxExclusionEnabled[msg.sender], "Address not approved for tax free transfers");
        _excludeAddressFromTax(_sender);
        IERC20(nebula).transferFrom(_sender, _recipient, _amt);
        _includeAddressInTax(_sender);
    }

    function setTaxExclusionForAddress(address _address, bool _excluded) external onlyOperator {
        taxExclusionEnabled[_address] = _excluded;
    }

    function _approveTokenIfNeeded(address _token, address _router) private {
        if (IERC20(_token).allowance(address(this), _router) == 0) {
            IERC20(_token).approve(_router, type(uint256).max);
        }
    }
}
