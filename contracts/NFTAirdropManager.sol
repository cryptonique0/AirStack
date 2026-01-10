// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IAccessControlLiteNFT {
    function hasPermission(address user, string memory permission) external view returns (bool);
}

interface IKYCAMLNFT { function isCompliant(address user) external view returns (bool); }

contract NFTAirdropManager is Ownable, ReentrancyGuard, Pausable {
    enum NFTType { ERC721, ERC1155 }

    struct NFTAirdrop {
        address nftContract;
        NFTType nftType;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    struct Allocation {
        uint256 tokenId;
        uint256 quantity; // for ERC1155
        bool claimed;
    }

    mapping(uint256 => NFTAirdrop) private drops;
    mapping(uint256 => mapping(address => Allocation[])) private allocations;
    uint256 private dropCounter;

    address public accessControl;
    address public compliance;
    bool public complianceRequired;

    event NFTAirdropCreated(uint256 indexed dropId, address indexed nft, NFTType nftType, uint256 startTime, uint256 endTime);
    event NFTAllocated(uint256 indexed dropId, address indexed user, uint256 tokenId, uint256 quantity);
    event NFTClaimed(uint256 indexed dropId, address indexed user, uint256 tokenId, uint256 quantity);
    event AccessControlUpdated(address indexed accessControl);
    event ComplianceUpdated(address indexed compliance, bool required);

    constructor() Ownable(msg.sender) {}

    modifier onlyOwnerOrRole(string memory permission) {
        if (msg.sender != owner()) {
            require(accessControl != address(0) && IAccessControlLiteNFT(accessControl).hasPermission(msg.sender, permission), "Not authorized");
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
            require(IKYCAMLNFT(compliance).isCompliant(user), "Not compliant");
        }
    }

    function createNFTAirdrop(address nft, NFTType nftType, uint256 startTime, uint256 endTime)
        external
        onlyOwnerOrRole("canCreateAirdrop")
        returns (uint256)
    {
        require(nft != address(0), "Invalid NFT");
        require(startTime < endTime && startTime >= block.timestamp, "Invalid time");

        dropCounter++;
        uint256 id = dropCounter;

        drops[id] = NFTAirdrop({
            nftContract: nft,
            nftType: nftType,
            startTime: startTime,
            endTime: endTime,
            active: true
        });

        emit NFTAirdropCreated(id, nft, nftType, startTime, endTime);
        return id;
    }

    function batchAllocate(uint256 dropId, address[] calldata users, uint256[] calldata tokenIds, uint256[] calldata quantities)
        external
        onlyOwnerOrRole("canManageUsers")
    {
        require(users.length == tokenIds.length && users.length == quantities.length, "Length mismatch");
        require(users.length <= 500, "Too many");
        require(drops[dropId].nftContract != address(0), "Not found");

        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Bad user");
            uint256 qty = drops[dropId].nftType == NFTType.ERC721 ? 1 : quantities[i];
            allocations[dropId][users[i]].push(Allocation({ tokenId: tokenIds[i], quantity: qty, claimed: false }));
            emit NFTAllocated(dropId, users[i], tokenIds[i], qty);
        }
    }

    function deactivate(uint256 dropId) external onlyOwnerOrRole("canApproveAirdrop") {
        require(drops[dropId].nftContract != address(0), "Not found");
        drops[dropId].active = false;
    }

    function activate(uint256 dropId) external onlyOwnerOrRole("canApproveAirdrop") {
        require(drops[dropId].nftContract != address(0), "Not found");
        drops[dropId].active = true;
    }

    function pause() external onlyOwnerOrRole("canEmergencyPause") { _pause(); }
    function unpause() external onlyOwnerOrRole("canEmergencyPause") { _unpause(); }

    function claim(uint256 dropId) external nonReentrant whenNotPaused {
        NFTAirdrop memory drop = drops[dropId];
        require(drop.nftContract != address(0), "Not found");
        require(drop.active, "Inactive");
        require(block.timestamp >= drop.startTime && block.timestamp <= drop.endTime, "Not active");

        Allocation[] storage allocs = allocations[dropId][msg.sender];
        require(allocs.length > 0, "No allocation");
        _requireCompliance(msg.sender);

        for (uint256 i = 0; i < allocs.length; i++) {
            require(!allocs[i].claimed, "Already claimed");
            allocs[i].claimed = true;
            if (drop.nftType == NFTType.ERC721) {
                IERC721(drop.nftContract).transferFrom(address(this), msg.sender, allocs[i].tokenId);
            } else {
                IERC1155(drop.nftContract).safeTransferFrom(address(this), msg.sender, allocs[i].tokenId, allocs[i].quantity, "");
            }
            emit NFTClaimed(dropId, msg.sender, allocs[i].tokenId, allocs[i].quantity);
        }
    }

    function getAllocations(uint256 dropId, address user) external view returns (Allocation[] memory) {
        return allocations[dropId][user];
    }

    // Emergency recovery
    function recoverNFT(address nft, NFTType nftType, uint256 tokenId, uint256 quantity) external onlyOwnerOrRole("canWithdraw") {
        if (nftType == NFTType.ERC721) {
            IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
        } else {
            IERC1155(nft).safeTransferFrom(address(this), msg.sender, tokenId, quantity, "");
        }
    }

    // ERC1155 receiver hooks
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
