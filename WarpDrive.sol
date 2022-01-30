// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/ITreasury.sol";

contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public share;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        share.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        uint256 userShare = _balances[msg.sender];
        require(userShare >= amount, "Warp Drive: withdraw request greater than staked amount");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = userShare.sub(amount);
        share.safeTransfer(msg.sender, amount);
    }
}

/*

Polarlys Finance

*/
contract WarpDrive is ShareWrapper, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    struct Warpseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct WarpDriveSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    IERC20 public nebula;
    ITreasury public treasury;

    mapping(address => Warpseat) public warpers;
    WarpDriveSnapshot[] public warpdriveHistory;

    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    /* ========== Modifiers =============== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Warp Drive: caller is not the operator");
        _;
    }

    modifier warperExists() {
        require(balanceOf(msg.sender) > 0, "Warp Drive: The warper does not exist");
        _;
    }

    modifier updateReward(address warper) {
        if (warper != address(0)) {
            Warpseat memory seat = warpers[warper];
            seat.rewardEarned = earned(warper);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            warpers[warper] = seat;
        }
        _;
    }

    modifier notInitialized() {
        require(!initialized, "Warp Drive: already initialized");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        IERC20 _nebula,
        IERC20 _share,
        ITreasury _treasury
    ) public notInitialized {
        nebula = _nebula;
        share = _share;
        treasury = _treasury;

        WarpDriveSnapshot memory genesisSnapshot = WarpDriveSnapshot({time: block.number, rewardReceived: 0, rewardPerShare: 0});
        warpdriveHistory.push(genesisSnapshot);

        withdrawLockupEpochs = 6; // Lock for 6 epochs (36h) before release withdraw
        rewardLockupEpochs = 3; // Lock for 3 epochs (18h) before release claimReward

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        require(_withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 56, "_withdrawLockupEpochs: out of range"); // <= 2 week
        withdrawLockupEpochs = _withdrawLockupEpochs;
        rewardLockupEpochs = _rewardLockupEpochs;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return warpdriveHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (WarpDriveSnapshot memory) {
        return warpdriveHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address warper) public view returns (uint256) {
        return warpers[warper].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address warper) internal view returns (WarpDriveSnapshot memory) {
        return warpdriveHistory[getLastSnapshotIndexOf(warper)];
    }

    function canWithdraw(address warper) external view returns (bool) {
        return warpers[warper].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch();
    }

    function canClaimReward(address warper) external view returns (bool) {
        return warpers[warper].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getNebulaPrice() external view returns (uint256) {
        return treasury.getNebulaPrice();
    }

    // =========== Nebula getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address warper) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(warper).rewardPerShare;

        return balanceOf(warper).mul(latestRPS.sub(storedRPS)).div(1e18).add(warpers[warper].rewardEarned);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) public override onlyOneBlock updateReward(msg.sender) {
        require(amount > 0, "Warp Drive: Cannot stake 0");
        super.stake(amount);
        warpers[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override onlyOneBlock warperExists updateReward(msg.sender) {
        require(amount > 0, "Warp Drive: Cannot withdraw 0");
        require(warpers[msg.sender].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch(), "Warp Drive: still in withdraw lockup");
        claimReward();
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 reward = warpers[msg.sender].rewardEarned;
        if (reward > 0) {
            require(warpers[msg.sender].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch(), "Warp Drive: still in reward lockup");
            warpers[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
            warpers[msg.sender].rewardEarned = 0;
            nebula.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 amount) external onlyOneBlock onlyOperator {
        require(amount > 0, "Warp Drive: Cannot allocate 0");
        require(totalSupply() > 0, "Warp Drive: Cannot allocate when totalSupply is 0");

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply()));

        WarpDriveSnapshot memory newSnapshot = WarpDriveSnapshot({time: block.number, rewardReceived: amount, rewardPerShare: nextRPS});
        warpdriveHistory.push(newSnapshot);

        nebula.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(nebula), "nebula");
        require(address(_token) != address(share), "share");
        _token.safeTransfer(_to, _amount);
    }
}
