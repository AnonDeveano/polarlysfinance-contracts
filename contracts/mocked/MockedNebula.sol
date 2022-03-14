// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../Nebula.sol";


contract MockedNebula is Nebula{
    constructor() public {}

    function mint(uint256 amount) external returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }
}