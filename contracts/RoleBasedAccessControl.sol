// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RoleBasedAccessControl
 * @notice Minimal role registry for composable gating.
 */
contract RoleBasedAccessControl is Ownable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    mapping(bytes32 => mapping(address => bool)) public hasRole;
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    constructor() Ownable(msg.sender) {
        hasRole[ADMIN_ROLE][msg.sender] = true;
        emit RoleGranted(ADMIN_ROLE, msg.sender, msg.sender);
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole[role][msg.sender], "Missing role");
        _;
    }

    function grantRole(bytes32 role, address account) external onlyOwner {
        hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) external onlyOwner {
        hasRole[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function hasRoleFor(address account, bytes32 role) external view returns (bool) {
        return hasRole[role][account];
    }
}
