// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SnapshotEligibility
 * @notice Tracks token balances at a snapshot to validate eligibility.
 */
contract SnapshotEligibility is Ownable {
    IERC20 public immutable token;
    uint256 public snapshotId;
    mapping(address => uint256) public balancesAtSnapshot;

    event SnapshotTaken(uint256 id);

    constructor(address tokenAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "Bad token");
        token = IERC20(tokenAddress);
    }

    function takeSnapshot(address[] calldata accounts) external onlyOwner {
        snapshotId += 1;
        for (uint256 i = 0; i < accounts.length; i++) {
            balancesAtSnapshot[accounts[i]] = token.balanceOf(accounts[i]);
        }
        emit SnapshotTaken(snapshotId);
    }

    function isEligible(address account, uint256 minBalance) external view returns (bool) {
        return balancesAtSnapshot[account] >= minBalance;
    }
}
