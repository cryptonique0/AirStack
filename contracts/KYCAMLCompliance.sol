// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title KYCAMLCompliance
 * @notice Simple registry of approved addresses for compliance checks.
 */
contract KYCAMLCompliance is Ownable {
    mapping(address => bool) public approved;
    event Approved(address indexed user, bool status);

    constructor() Ownable(msg.sender) {}

    function setApproved(address user, bool status) external onlyOwner {
        approved[user] = status;
        emit Approved(user, status);
    }

    function batchApprove(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            approved[users[i]] = status;
            emit Approved(users[i], status);
        }
    }

    function isApproved(address user) external view returns (bool) {
        return approved[user];
    }
}
