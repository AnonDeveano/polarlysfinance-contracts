// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./owner/Operator.sol";

/*

Polarlys Finance

*/
contract Borealis is ERC20Burnable, Operator {
    using SafeMath for uint256;

    // TOTAL MAX SUPPLY = 70,000 Borealis
    uint256 public constant FARMING_POOL_REWARD_ALLOCATION = 59500 ether;

    uint256 public constant VESTING_DURATION = 365 days;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public communityFundRewardRate;
    uint256 public teamFundRewardRate;
    uint256 public devFundRewardRate;

    address public communityFund;
    address public teamFund;
    address public devFund;

    uint256 public communityFundLastClaimed;
    uint256 public teamFundLastClaimed;
    uint256 public devFundLastClaimed;

    bool public rewardPoolDistributed = false;
    bool public isAllocated = false;

    constructor(
        uint256 _startTime,
        address _communityFund,
        address _devFund,
        address _teamFund
    ) public ERC20("Borealis", "Borealis") {
        _mint(msg.sender, 1 ether); // mint 1 Borealis for initial pools deployment

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;

        communityFundLastClaimed = startTime;
        teamFundLastClaimed = startTime;
        devFundLastClaimed = startTime;

        communityFundRewardRate = COMMUNITY_FUND_POOL_ALLOCATION.div(VESTING_DURATION);
        devFundRewardRate = DEV_FUND_POOL_ALLOCATION.div(VESTING_DURATION);

        require(_devFund != address(0), "Address cannot be 0");
        devFund = _devFund;

        require(_teamFund != address(0), "Address cannot be 0");
        teamFund = _teamFund;

        require(_communityFund != address(0), "Address cannot be 0");
        communityFund = _communityFund;
    }

    function setAllocations(
        uint256 _communityAllocation,
        uint256 _devAllocation,
        uint256 _teamAllocation
    ) external {
        require(_communityAllocation <= 10000 ether, "community allocation too high");
        require(_devAllocation <= 2100 ether, "dev allocation too high");
        require(_teamAllocation <= 2100 ether, "team allocation too high");

        isAllocated = true;

        communityFundRewardRate = _communityAllocation.div(VESTING_DURATION);
        teamFundRewardRate = _teamAllocation.div(VESTING_DURATION);
        devFundRewardRate = _devAllocation.div(VESTING_DURATION);
    }

    function setTreasuryFund(address _communityFund) external {
        require(msg.sender == devFund, "!dev");
        communityFund = _communityFund;
    }

    function setDevFund(address _devFund) external {
        require(msg.sender == devFund, "!dev");
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    function setTeamFund(address _teamFund) external {
        require(msg.sender == teamFund, "!team");
        require(_teamFund != address(0), "zero");
        teamFund = _teamFund;
    }

    function unclaimedTreasuryFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (communityFundLastClaimed >= _now) return 0;
        _pending = _now.sub(communityFundLastClaimed).mul(communityFundRewardRate);
    }

    function unclaimedDevFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (devFundLastClaimed >= _now) return 0;
        _pending = _now.sub(devFundLastClaimed).mul(devFundRewardRate);
    }

    function unclaimedTeamFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (teamFundLastClaimed >= _now) return 0;
        _pending = _now.sub(teamFundLastClaimed).mul(teamFundRewardRate);
    }

    /**
     * @dev Claim pending rewards to community and dev fund
     */
    function claimRewards() external {
        require(isAllocated, "not allocated to funds yet");
        uint256 _pending = unclaimedTreasuryFund();
        if (_pending > 0 && communityFund != address(0)) {
            _mint(communityFund, _pending);
            communityFundLastClaimed = block.timestamp;
        }
        _pending = unclaimedDevFund();
        if (_pending > 0 && devFund != address(0)) {
            _mint(devFund, _pending);
            devFundLastClaimed = block.timestamp;
        }
        _pending - unclaimedTeamFund();
        if (_pending > 0 && teamFund != address(0)) {
            _mint(teamFund, _pending);
            teamFundLastClaimed = block.timestamp;
        }
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(address _farmingIncentiveFund) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_farmingIncentiveFund != address(0), "!_farmingIncentiveFund");
        rewardPoolDistributed = true;
        _mint(_farmingIncentiveFund, FARMING_POOL_REWARD_ALLOCATION);
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}
