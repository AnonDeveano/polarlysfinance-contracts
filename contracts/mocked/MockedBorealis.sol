// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../Borealis.sol";


contract MockedBorealis is Borealis {
    constructor(
        uint256 _startTime,
        address _communityFund,
        address _devFund,
        uint256 _teamFund
    ) public Borealis(
        _startTime,
        _communityFund,
        _devFund,
        _teamFund
    ) 

    function mint(uint256 amount) external returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }
}