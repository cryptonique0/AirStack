// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IAccessControlLiteLP {
    function hasPermission(address user, string memory permission) external view returns (bool);
}

interface IKYCAMLLP { function isCompliant(address user) external view returns (bool); }

contract LPTokenDistributor is Ownable, ReentrancyGuard, Pausable {
    struct LPAirdrop {
        address lpToken;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    struct Allocation { uint256 amount; bool claimed; }

    mapping(uint256 => LPAirdrop) private drops;
    mapping(uint256 => mapping(address => Allocation)) private allocations;
    uint256 private dropCounter;

    address public accessControl;
    address public compliance;
    bool public complianceRequired;

    event LPAirdropCreated(uint256 indexed id, address indexed lpToken, uint256 total, uint256 startTime, uint256 endTime);
    event LPAllocated(uint256 indexed id, address indexed user, uint256 amount);
    event LPClaimed(uint256 indexed id, address indexed user, uint256 amount);
    event AccessControlUpdated(address indexed accessControl);
    event ComplianceUpdated(address indexed compliance, bool required);

    constructor() Ownable(msg.sender) {}

    modifier onlyOwnerOrRole(string memory permission) {
        if (msg.sender != owner()) {
            require(accessControl != address(0) && IAccessControlLiteLP(accessControl).hasPermission(msg.sender, permission), "Not authorized");
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
            require(IKYCAMLLP(compliance).isCompliant(user), "Not compliant");
        }
    }

    function createLPAirdrop(address lpToken, uint256 totalAmount, uint256 startTime, uint256 endTime)
        external
        onlyOwnerOrRole("canCreateAirdrop")
        returns (uint256)
    {
        require(lpToken != address(0), "Invalid token");
        require(totalAmount > 0, "Invalid amount");
        require(startTime < endTime && startTime >= block.timestamp, "Invalid time");

        dropCounter++;
        uint256 id = dropCounter;

        drops[id] = LPAirdrop({
            lpToken: lpToken,
            totalAmount: totalAmount,
            claimedAmount: 0,
            startTime: startTime,
            endTime: endTime,
            active: true
        });

        emit LPAirdropCreated(id, lpToken, totalAmount, startTime, endTime);
        return id;
    }

    function batchAllocate(uint256 dropId, address[] calldata users, uint256[] calldata amounts)
        external
        onlyOwnerOrRole("canManageUsers")
    {
        require(users.length == amounts.length, "Length mismatch");
        require(users.length <= 500, "Too many");
        require(drops[dropId].lpToken != address(0), "Not found");

        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Bad user");
            require(amounts[i] > 0, "Bad amount");
            allocations[dropId][users[i]] = Allocation({ amount: amounts[i], claimed: false });
            emit LPAllocated(dropId, users[i], amounts[i]);
        }
    }

    function deactivate(uint256 dropId) external onlyOwnerOrRole("canApproveAirdrop") {
        require(drops[dropId].lpToken != address(0), "Not found");
        drops[dropId].active = false;
    }

    function activate(uint256 dropId) external onlyOwnerOrRole("canApproveAirdrop") {
        require(drops[dropId].lpToken != address(0), "Not found");
        drops[dropId].active = true;
    }

    function pause() external onlyOwnerOrRole("canEmergencyPause") { _pause(); }
    function unpause() external onlyOwnerOrRole("canEmergencyPause") { _unpause(); }

    function claim(uint256 dropId) external nonReentrant whenNotPaused {
        LPAirdrop storage drop = drops[dropId];
        require(drop.lpToken != address(0), "Not found");
        require(drop.active, "Inactive");
        require(block.timestamp >= drop.startTime && block.timestamp <= drop.endTime, "Not active");

        Allocation storage alloc = allocations[dropId][msg.sender];
        require(alloc.amount > 0, "No allocation");
        require(!alloc.claimed, "Claimed");

        _requireCompliance(msg.sender);

        alloc.claimed = true;
        drop.claimedAmount += alloc.amount;
        require(IERC20(drop.lpToken).transfer(msg.sender, alloc.amount), "Transfer failed");

        emit LPClaimed(dropId, msg.sender, alloc.amount);
    }

    function recoverTokens(address token, uint256 amount) external onlyOwnerOrRole("canWithdraw") {
        require(token != address(0), "Invalid token");
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function getDrop(uint256 dropId) external view returns (LPAirdrop memory) { return drops[dropId]; }
    function getAllocation(uint256 dropId, address user) external view returns (Allocation memory) { return allocations[dropId][user]; }
}
