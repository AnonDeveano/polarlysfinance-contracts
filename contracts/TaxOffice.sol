// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./owner/Operator.sol";
import "./interfaces/ITaxable.sol";

/*

Polarlys Finance

*/
contract TaxOffice is Operator {
    address public nebula;

    constructor(address _nebula) public {
        require(_nebula != address(0), "nebula address cannot be 0");
        nebula = _nebula;
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
        return ITaxable(nebula).excludeAddress(_address);
    }

    function includeAddressInTax(address _address) external onlyOperator returns (bool) {
        return ITaxable(nebula).includeAddress(_address);
    }

    function setTaxableNebulaOracle(address _nebulaOracle) external onlyOperator {
        ITaxable(nebula).setNebulaOracle(_nebulaOracle);
    }

    function transferTaxOffice(address _newTaxOffice) external onlyOperator {
        ITaxable(nebula).setTaxOffice(_newTaxOffice);
    }
}
