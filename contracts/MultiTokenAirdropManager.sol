// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IAccessControlLite {
    function hasPermission(address user, string memory permission) external view returns (bool);
}

interface IKYCAML { function isCompliant(address user) external view returns (bool); }

/**
 * @title MultiTokenAirdropManager
 * @notice Distribute any ERC20 token with optional whitelist + compliance gating
 */
contract MultiTokenAirdropManager is Ownable, ReentrancyGuard, Pausable {
    struct TokenAirdrop {
        address tokenContract;
        uint256 totalTokens;
        uint256 claimedTokens;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    struct TokenAllocation {
        uint256 amount;
        bool claimed;
    }

    mapping(uint256 => TokenAirdrop) private airdrops;
    mapping(uint256 => mapping(address => TokenAllocation)) private allocations;

    uint256 private airdropCounter;

    // Optional controls
    address public accessControl;
    address public compliance;
    bool public complianceRequired;

    event TokenAirdropCreated(uint256 indexed airdropId, address indexed token, uint256 total, uint256 startTime, uint256 endTime);
    event TokenAllocated(uint256 indexed airdropId, address indexed user, uint256 amount);
    event TokenClaimed(uint256 indexed airdropId, address indexed user, uint256 amount);
    event AccessControlUpdated(address indexed accessControl);
    event ComplianceUpdated(address indexed compliance, bool required);

    constructor() Ownable(msg.sender) {}

    modifier onlyOwnerOrRole(string memory permission) {
        if (msg.sender != owner()) {
            require(accessControl != address(0) && IAccessControlLite(accessControl).hasPermission(msg.sender, permission), "Not authorized");
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
            require(IKYCAML(compliance).isCompliant(user), "Not compliant");
        }
    }

    // View functions
    function getAirdrop(uint256 airdropId) external view returns (TokenAirdrop memory) {
        require(airdrops[airdropId].tokenContract != address(0), "Airdrop not found");
        return airdrops[airdropId];
    }

    function getAllocation(uint256 airdropId, address user) external view returns (TokenAllocation memory) {
        return allocations[airdropId][user];
    }

    // Admin
    function createTokenAirdrop(address token, uint256 totalTokens, uint256 startTime, uint256 endTime)
        external
        onlyOwnerOrRole("canCreateAirdrop")
        returns (uint256)
    {
        require(token != address(0), "Invalid token");
        require(totalTokens > 0, "Invalid amount");
        require(startTime < endTime && startTime >= block.timestamp, "Invalid timing");

        airdropCounter++;
        uint256 id = airdropCounter;

        airdrops[id] = TokenAirdrop({
            tokenContract: token,
            totalTokens: totalTokens,
            claimedTokens: 0,
            startTime: startTime,
            endTime: endTime,
            active: true
        });

        emit TokenAirdropCreated(id, token, totalTokens, startTime, endTime);
        return id;
    }

    function batchAllocate(uint256 airdropId, address[] calldata users, uint256[] calldata amounts)
        external
        onlyOwnerOrRole("canManageUsers")
    {
        require(users.length == amounts.length, "Length mismatch");
        require(users.length <= 500, "Too many users");
        require(airdrops[airdropId].tokenContract != address(0), "Airdrop not found");

        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Invalid user");
            require(amounts[i] > 0, "Invalid amount");
            allocations[airdropId][users[i]].amount = amounts[i];
            allocations[airdropId][users[i]].claimed = false;
            emit TokenAllocated(airdropId, users[i], amounts[i]);
        }
    }

    function deactivateAirdrop(uint256 airdropId) external onlyOwnerOrRole("canApproveAirdrop") {
        require(airdrops[airdropId].tokenContract != address(0), "Airdrop not found");
        airdrops[airdropId].active = false;
    }

    function activateAirdrop(uint256 airdropId) external onlyOwnerOrRole("canApproveAirdrop") {
        require(airdrops[airdropId].tokenContract != address(0), "Airdrop not found");
        airdrops[airdropId].active = true;
    }

    function pause() external onlyOwnerOrRole("canEmergencyPause") {
        _pause();
    }

    function unpause() external onlyOwnerOrRole("canEmergencyPause") {
        _unpause();
    }

    // Claim
    function claimTokens(uint256 airdropId) external nonReentrant whenNotPaused {
        TokenAirdrop storage drop = airdrops[airdropId];
        require(drop.tokenContract != address(0), "Airdrop not found");
        require(drop.active, "Inactive");
        require(block.timestamp >= drop.startTime && block.timestamp <= drop.endTime, "Not active");

        TokenAllocation storage alloc = allocations[airdropId][msg.sender];
        require(alloc.amount > 0, "No allocation");
        require(!alloc.claimed, "Already claimed");

        _requireCompliance(msg.sender);

        alloc.claimed = true;
        drop.claimedTokens += alloc.amount;

        require(IERC20(drop.tokenContract).transfer(msg.sender, alloc.amount), "Transfer failed");
        emit TokenClaimed(airdropId, msg.sender, alloc.amount);
    }

    // Emergency
    function recoverTokens(address token, uint256 amount) external onlyOwnerOrRole("canWithdraw") {
        require(token != address(0), "Invalid token");
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }
}
