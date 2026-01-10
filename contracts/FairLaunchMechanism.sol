// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title FairLaunchMechanism
 * @notice Collects deposits during a window then distributes tokens pro-rata.
 */
contract FairLaunchMechanism is Ownable, ReentrancyGuard {
    IERC20 public immutable saleToken;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalDeposits;
    uint256 public tokenPool;
    bool public finalized;

    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Finalized(uint256 tokenPool, uint256 totalDeposits);
    event Claimed(address indexed user, uint256 amount);

    constructor(address _saleToken, uint256 _start, uint256 _end) Ownable(msg.sender) {
        require(_saleToken != address(0), "Bad token");
        require(_end > _start, "Bad window");
        saleToken = IERC20(_saleToken);
        startTime = _start;
        endTime = _end;
    }

    function deposit() external payable {
        require(block.timestamp >= startTime && block.timestamp < endTime, "Not active");
        require(msg.value > 0, "Zero");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function supplyTokenPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Zero");
        require(saleToken.transferFrom(msg.sender, address(this), amount), "Transfer fail");
        tokenPool += amount;
    }

    function finalize() external onlyOwner {
        require(block.timestamp >= endTime, "Not ended");
        require(!finalized, "Done");
        require(tokenPool > 0 && totalDeposits > 0, "No pool");
        finalized = true;
        emit Finalized(tokenPool, totalDeposits);
    }

    function claim() external nonReentrant {
        require(finalized, "Not finalized");
        uint256 userDeposit = deposits[msg.sender];
        require(userDeposit > 0, "No deposit");
        uint256 share = (tokenPool * userDeposit) / totalDeposits;
        deposits[msg.sender] = 0;
        require(saleToken.transfer(msg.sender, share), "Claim fail");
        emit Claimed(msg.sender, share);
    }
}
