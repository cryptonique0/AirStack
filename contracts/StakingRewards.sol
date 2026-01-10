// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title StakingRewards
 * @notice Minimal staking with linear rewards.
 */
contract StakingRewards is Ownable, ReentrancyGuard {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    uint256 public rewardRate; // reward per second per token staked (scaled 1e18)

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 rate);

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) Ownable(msg.sender) {
        require(_stakingToken != address(0) && _rewardToken != address(0), "Bad token");
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    function setRewardRate(uint256 rate) external onlyOwner {
        rewardRate = rate;
        emit RewardRateUpdated(rate);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero");
        _accrue(msg.sender);
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake fail");
        stakes[msg.sender].amount += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero");
        StakeInfo storage s = stakes[msg.sender];
        require(s.amount >= amount, "Too much");
        _accrue(msg.sender);
        s.amount -= amount;
        totalStaked -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Unstake fail");
        emit Unstaked(msg.sender, amount);
    }

    function claim() external nonReentrant {
        _accrue(msg.sender);
    }

    function pendingRewards(address user) public view returns (uint256) {
        StakeInfo memory s = stakes[user];
        if (s.amount == 0) return 0;
        uint256 elapsed = block.timestamp - s.lastUpdate;
        uint256 reward = (elapsed * rewardRate * s.amount) / 1e18;
        return reward + s.rewardDebt;
    }

    function _accrue(address user) internal {
        StakeInfo storage s = stakes[user];
        uint256 reward = pendingRewards(user);
        s.lastUpdate = block.timestamp;
        s.rewardDebt = 0;
        if (reward > 0) {
            require(rewardToken.transfer(user, reward), "Reward fail");
            emit RewardClaimed(user, reward);
        }
    }
}
