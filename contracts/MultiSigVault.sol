// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MultiSigVault
 * @notice M-of-N multisig for large transfers with optional delay
 */
contract MultiSigVault is Ownable, ReentrancyGuard {
    struct Transaction {
        address to;
        address token;
        uint256 amount;
        uint256 createdAt;
        bool executed;
        uint256 signatures;
    }

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public signers;

    uint256 public transactionCount;
    uint256 public requiredSignatures;
    uint256 public signerCount;
    uint256 public executionDelay; // seconds

    event TransactionCreated(uint256 indexed txId, address indexed to, address indexed token, uint256 amount);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event RequiredSignaturesChanged(uint256 requiredSignatures);
    event ExecutionDelayChanged(uint256 delay);

    modifier onlySigner() {
        require(signers[msg.sender], "Not signer");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function initialize(address[] memory _signers, uint256 _requiredSignatures, uint256 _executionDelay) external onlyOwner {
        require(_signers.length >= _requiredSignatures, "Bad signers");
        require(_requiredSignatures > 0, "Need sigs");

        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Bad signer");
            if (!signers[_signers[i]]) {
                signers[_signers[i]] = true;
                signerCount++;
                emit SignerAdded(_signers[i]);
            }
        }

        requiredSignatures = _requiredSignatures;
        executionDelay = _executionDelay;
    }

    function addSigner(address signer) external onlyOwner {
        require(signer != address(0), "Bad signer");
        require(!signers[signer], "Exists");
        signers[signer] = true;
        signerCount++;
        emit SignerAdded(signer);
    }

    function removeSigner(address signer) external onlyOwner {
        require(signers[signer], "Not signer");
        require(signerCount > requiredSignatures, "Keep quorum");
        signers[signer] = false;
        signerCount--;
        emit SignerRemoved(signer);
    }

    function setRequiredSignatures(uint256 required) external onlyOwner {
        require(required > 0 && required <= signerCount, "Bad required");
        requiredSignatures = required;
        emit RequiredSignaturesChanged(required);
    }

    function setExecutionDelay(uint256 delaySeconds) external onlyOwner {
        executionDelay = delaySeconds;
        emit ExecutionDelayChanged(delaySeconds);
    }

    function createTransaction(address to, address token, uint256 amount) external onlyOwner returns (uint256) {
        require(to != address(0), "Bad to");
        require(amount > 0, "Bad amount");

        uint256 txId = transactionCount++;
        transactions[txId] = Transaction({ to: to, token: token, amount: amount, createdAt: block.timestamp, executed: false, signatures: 0 });
        emit TransactionCreated(txId, to, token, amount);
        return txId;
    }

    function confirmTransaction(uint256 txId) external onlySigner {
        require(txId < transactionCount, "Invalid tx");
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "Executed");
        require(!confirmations[txId][msg.sender], "Confirmed");
        confirmations[txId][msg.sender] = true;
        txn.signatures += 1;
        emit TransactionConfirmed(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external nonReentrant {
        require(txId < transactionCount, "Invalid tx");
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "Executed");
        require(txn.signatures >= requiredSignatures, "Not enough sigs");
        require(block.timestamp >= txn.createdAt + executionDelay, "Delay not met");

        txn.executed = true;
        if (txn.token == address(0)) {
            (bool ok,) = txn.to.call{value: txn.amount}("");
            require(ok, "ETH fail");
        } else {
            require(IERC20(txn.token).transfer(txn.to, txn.amount), "ERC20 fail");
        }

        emit TransactionExecuted(txId);
    }

    receive() external payable {}
}
