// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IAccessControlLiteDyn {
    function hasPermission(address user, string memory permission) external view returns (bool);
}

interface IKYCDyn { function isCompliant(address user) external view returns (bool); }

interface IPriceFeed { function getLatestPrice(address token) external view returns (uint256); }
interface IPoolSizeOracle { function getPoolSize(address token) external view returns (uint256); }

contract DynamicAllocationManager is Ownable, ReentrancyGuard, Pausable {
    enum AdjustmentType { PRICE_BASED, POOL_SIZE_BASED, TIME_BASED }

    struct DynamicAirdrop {
        address token;
        uint256 baseAllocation;
        uint256 totalTokens;
        uint256 claimedTokens;
        uint256 startTime;
        uint256 endTime;
        AdjustmentType adjustmentType;
        bool active;
    }

    struct AdjustmentRule {
        uint256 threshold;
        uint256 minMultiplier; // percent
        uint256 maxMultiplier; // percent
        address priceOracle;
        address poolOracle;
    }

    struct Allocation {
        uint256 baseAmount;
        uint256 adjustedAmount;
        bool claimed;
    }

    mapping(uint256 => DynamicAirdrop) private drops;
    mapping(uint256 => AdjustmentRule) private rules;
    mapping(uint256 => mapping(address => Allocation)) private allocations;
    uint256 private dropCounter;

    address public accessControl;
    address public compliance;
    bool public complianceRequired;

    event DynamicAirdropCreated(uint256 indexed id, address indexed token, uint256 baseAllocation, AdjustmentType adjustmentType);
    event AllocationSet(uint256 indexed id, address indexed user, uint256 baseAmount, uint256 adjustedAmount);
    event TokensClaimed(uint256 indexed id, address indexed user, uint256 amount);
    event RuleSet(uint256 indexed id, uint256 threshold, uint256 minMultiplier, uint256 maxMultiplier);
    event AccessControlUpdated(address indexed accessControl);
    event ComplianceUpdated(address indexed compliance, bool required);

    constructor() Ownable(msg.sender) {}

    modifier onlyOwnerOrRole(string memory permission) {
        if (msg.sender != owner()) {
            require(accessControl != address(0) && IAccessControlLiteDyn(accessControl).hasPermission(msg.sender, permission), "Not authorized");
        }
        _;
    }

    function setAccessControl(address _accessControl) external onlyOwner {
        accessControl = _accessControl;
        emit AccessControlUpdated(_accessControl);
    }

    function setCompliance(address _compliance, bool _required) external onlyOwner {
        compliance = _compliance;
        complianceRequired = _required;
        emit ComplianceUpdated(_compliance, _required);
    }

    function _requireCompliance(address user) internal view {
        if (complianceRequired && compliance != address(0)) {
            require(IKYCDyn(compliance).isCompliant(user), "Not compliant");
        }
    }

    function createDynamicAirdrop(address token, uint256 baseAllocation, uint256 totalTokens, AdjustmentType adjustmentType, uint256 startTime, uint256 endTime)
        external
        onlyOwnerOrRole("canCreateAirdrop")
        returns (uint256)
    {
        require(token != address(0), "Invalid token");
        require(baseAllocation > 0 && totalTokens > 0, "Invalid amounts");
        require(startTime < endTime && startTime >= block.timestamp, "Invalid time");

        dropCounter++;
        uint256 id = dropCounter;

        drops[id] = DynamicAirdrop({
            token: token,
            baseAllocation: baseAllocation,
            totalTokens: totalTokens,
            claimedTokens: 0,
            startTime: startTime,
            endTime: endTime,
            adjustmentType: adjustmentType,
            active: true
        });

        emit DynamicAirdropCreated(id, token, baseAllocation, adjustmentType);
        return id;
    }

    function setAdjustmentRule(uint256 id, uint256 threshold, uint256 minMultiplier, uint256 maxMultiplier, address priceOracle, address poolOracle)
        external
        onlyOwnerOrRole("canConfigureSystem")
    {
        require(minMultiplier > 0 && minMultiplier <= maxMultiplier, "Bad multipliers");
        rules[id] = AdjustmentRule({ threshold: threshold, minMultiplier: minMultiplier, maxMultiplier: maxMultiplier, priceOracle: priceOracle, poolOracle: poolOracle });
        emit RuleSet(id, threshold, minMultiplier, maxMultiplier);
    }

    function batchAllocate(uint256 id, address[] calldata users, uint256[] calldata baseAmounts) external onlyOwnerOrRole("canManageUsers") {
        require(users.length == baseAmounts.length, "Length mismatch");
        require(users.length <= 500, "Too many");
        require(drops[id].token != address(0), "Not found");

        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Bad user");
            uint256 adjusted = _calculateAdjusted(baseAmounts[i], drops[id].adjustmentType, rules[id]);
            allocations[id][users[i]] = Allocation({ baseAmount: baseAmounts[i], adjustedAmount: adjusted, claimed: false });
            emit AllocationSet(id, users[i], baseAmounts[i], adjusted);
        }
    }

    function deactivate(uint256 id) external onlyOwnerOrRole("canApproveAirdrop") { require(drops[id].token != address(0), "Not found"); drops[id].active = false; }
    function activate(uint256 id) external onlyOwnerOrRole("canApproveAirdrop") { require(drops[id].token != address(0), "Not found"); drops[id].active = true; }
    function pause() external onlyOwnerOrRole("canEmergencyPause") { _pause(); }
    function unpause() external onlyOwnerOrRole("canEmergencyPause") { _unpause(); }

    function claim(uint256 id) external nonReentrant whenNotPaused {
        DynamicAirdrop storage drop = drops[id];
        require(drop.token != address(0), "Not found");
        require(drop.active, "Inactive");
        require(block.timestamp >= drop.startTime && block.timestamp <= drop.endTime, "Not active");

        Allocation storage alloc = allocations[id][msg.sender];
        require(alloc.adjustedAmount > 0, "No allocation");
        require(!alloc.claimed, "Claimed");

        _requireCompliance(msg.sender);

        alloc.claimed = true;
        drop.claimedTokens += alloc.adjustedAmount;

        require(IERC20(drop.token).transfer(msg.sender, alloc.adjustedAmount), "Transfer failed");
        emit TokensClaimed(id, msg.sender, alloc.adjustedAmount);
    }

    function getDrop(uint256 id) external view returns (DynamicAirdrop memory) { return drops[id]; }
    function getRule(uint256 id) external view returns (AdjustmentRule memory) { return rules[id]; }
    function getAllocation(uint256 id, address user) external view returns (Allocation memory) { return allocations[id][user]; }

    function _calculateAdjusted(uint256 baseAmount, AdjustmentType t, AdjustmentRule memory rule) internal view returns (uint256) {
        if (t == AdjustmentType.TIME_BASED) {
            uint256 elapsed = block.timestamp;
            uint256 duration = 30 days;
            if (elapsed >= duration) return (baseAmount * rule.minMultiplier) / 100;
            uint256 mult = rule.maxMultiplier - ((rule.maxMultiplier - rule.minMultiplier) * elapsed) / duration;
            return (baseAmount * mult) / 100;
        }
        if (t == AdjustmentType.PRICE_BASED) {
            require(rule.priceOracle != address(0), "No oracle");
            uint256 price = IPriceFeed(rule.priceOracle).getLatestPrice(dropCounter == 0 ? address(0) : drops[1].token);
            uint256 mult = price >= rule.threshold ? rule.maxMultiplier : rule.minMultiplier;
            return (baseAmount * mult) / 100;
        }
        if (t == AdjustmentType.POOL_SIZE_BASED) {
            require(rule.poolOracle != address(0), "No pool oracle");
            uint256 size = IPoolSizeOracle(rule.poolOracle).getPoolSize(dropCounter == 0 ? address(0) : drops[1].token);
            uint256 mult = size >= rule.threshold ? rule.maxMultiplier : rule.minMultiplier;
            return (baseAmount * mult) / 100;
        }
        return baseAmount;
    }
}
