// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ReferralBountySystem
 * @notice Simple referral rewards with cooldown to limit abuse.
 */
contract ReferralBountySystem is Ownable {
    IERC20 public immutable rewardToken;
    uint256 public rewardAmount;
    uint256 public cooldown;

    mapping(address => address) public referrerOf;
    mapping(address => uint256) public lastClaim;

    event Referred(address indexed user, address indexed referrer);
    event RewardClaimed(address indexed referrer, uint256 amount);
    event RewardUpdated(uint256 amount);
    event CooldownUpdated(uint256 cooldown);

    constructor(address token, uint256 _rewardAmount, uint256 _cooldown) Ownable(msg.sender) {
        require(token != address(0), "Bad token");
        rewardToken = IERC20(token);
        rewardAmount = _rewardAmount;
        cooldown = _cooldown;
    }

    function setRewardAmount(uint256 amount) external onlyOwner {
        rewardAmount = amount;
        emit RewardUpdated(amount);
    }

    function setCooldown(uint256 _cooldown) external onlyOwner {
        cooldown = _cooldown;
        emit CooldownUpdated(_cooldown);
    }

    function setReferrer(address referrer) external {
        require(referrer != msg.sender, "Self");
        require(referrerOf[msg.sender] == address(0), "Exists");
        referrerOf[msg.sender] = referrer;
        emit Referred(msg.sender, referrer);
    }

    function claimReferralReward() external {
        address referrer = referrerOf[msg.sender];
        require(referrer != address(0), "No referrer");
        require(block.timestamp >= lastClaim[referrer] + cooldown, "Cooldown");

        lastClaim[referrer] = block.timestamp;
        require(rewardToken.transfer(referrer, rewardAmount), "Transfer fail");
        emit RewardClaimed(referrer, rewardAmount);
    }
}
