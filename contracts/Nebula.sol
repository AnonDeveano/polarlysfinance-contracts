// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/SafeMath8.sol";
import "./owner/Operator.sol";
import "./interfaces/IOracle.sol";

/*
  
  Polarlys Finance
  
*/
contract Nebula is ERC20Burnable, Operator {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    // Initial distribution for the first 24h genesis pools
    uint256 public constant INITIAL_LAUNCH_DISTRIBUTION = 40000 ether; 
    // Distribution for airdrops wallet
    uint256 public constant INITIAL_AIRDROP_WALLET_DISTRIBUTION = 20000 ether; 

    // Have the rewards been distributed to the pools
    bool public rewardPoolDistributed = false;

    /**
     * @notice Constructs the NEBULA ERC-20 contract.
     */

    constructor() public ERC20("NEBULA", "NEBULA") {
        _mint(msg.sender, 1 ether);
    }

    /**
     * @notice Operator mints NEBULA to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of NEBULA to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(address _launcherAddress, address _airdropAddress) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_launcherAddress != address(0), "!_launcherAddress");
        require(_airdropAddress != address(0), "!_airdropAddress");
        rewardPoolDistributed = true;
        _mint(_launcherAddress, INITIAL_LAUNCH_DISTRIBUTION);
        _mint(_airdropAddress, INITIAL_AIRDROP_WALLET_DISTRIBUTION);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}
