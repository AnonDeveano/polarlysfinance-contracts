// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../Nebula.sol";


contract MockedNebula is Nebula{
    constructor() public ERC20("NEBULA", "NEBULA") {
        _mint(msg.sender, 5000 ether);
    }

    function mint(uint256 amount) external returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }
}