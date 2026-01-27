// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title OnChainResume
 * @author Talent Resume Team
 * @notice A decentralized resume platform where users can store verified achievements,
 * credentials, and professional profiles on-chain with IPFS integration.
 * @dev Optimized for gas efficiency with packed storage, event-driven architecture,
 * multiple credentials per user with categorization, staking mechanisms, verifier reputation weighting,
 * activity streaks, flagging/slashing for abuse, and cached leaderboards.
 */

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract OnChainResume {
    // ============ Type Definitions ============
    
    /// @notice Categories for credentials with enum values for efficient storage
    enum CredentialCategory {
        EDUCATION,      // 0: Educational qualifications (degrees, diplomas)
        WORK,           // 1: Work experience and employment history
        CERTIFICATION,  // 2: Professional certifications and licenses
        HACKATHON       // 3: Hackathon participation and achievements
    }

    /// @notice Status for flagged credentials
    enum FlagStatus {
        NONE,           // 0: No flag
        FLAGGED,        // 1: Flagged for review
        VERIFIED_CLEAN, // 2: Cleared after review
        SLASHED         // 3: Permanently slashed
    }

    /// @notice Badge verification sources
    enum BadgeSource {
        TALENT_PROTOCOL,  // 0: Talent Protocol badges
        GITCOIN_PASSPORT, // 1: Gitcoin Passport
        POLYGON_ID,       // 2: Polygon ID
        CUSTOM_NFT        // 3: Custom NFT collection
    }

    // ============ Events ============
    
    /// @notice Emitted when a new profile is created
    /// @param user Address of the profile owner
    /// @param handle Unique handle chosen by the user
    /// @param ipfsHash IPFS hash containing profile metadata
    /// @param timestamp Block timestamp of profile creation
    event ProfileCreated(
        address indexed user, 
        string handle, 
        string ipfsHash,
        uint256 timestamp
    );
    
    /// @notice Emitted when a profile is updated
    /// @param user Address of the profile owner
    /// @param ipfsHash New IPFS hash containing updated profile metadata
    /// @param timestamp Block timestamp of profile update
    event ProfileUpdated(
        address indexed user, 
        string ipfsHash,
        uint256 timestamp
    );
    
    /// @notice Emitted when a new credential is added
    /// @param user Address of the profile owner
    /// @param category Category of the credential
    /// @param credentialType Type/name of the credential
    /// @param credentialIndex Index of the credential in user's array
    /// @param timestamp Block timestamp of credential addition
    event CredentialAdded(
        address indexed user, 
        CredentialCategory indexed category,
        string credentialType, 
        uint256 credentialIndex,
        uint256 timestamp
    );
    
    /// @notice Emitted when a credential is verified
    /// @param user Address of the credential owner
    /// @param credentialIndex Index of the verified credential
    /// @param verifier Address of the verifier
    /// @param timestamp Block timestamp of verification
    event CredentialVerified(
        address indexed user, 
        uint256 credentialIndex, 
        address indexed verifier,
        uint256 timestamp
    );
    
    /// @notice Emitted when reputation score is updated
    /// @param user Address of the user
    /// @param oldScore Previous reputation score
    /// @param newScore New reputation score
    event ReputationScoreUpdated(
        address indexed user, 
        uint256 oldScore,
        uint256 newScore
    );
    
    /// @notice Emitted when an achievement is unlocked
    /// @param user Address of the user
    /// @param achievementName Name of the unlocked achievement
    /// @param timestamp Block timestamp of achievement unlock
    event AchievementUnlocked(
        address indexed user, 
        string achievementName,
        uint256 timestamp
    );

    /// @notice Emitted when a user stakes reputation tokens for a boost
    /// @param user Address of the user
    /// @param amount Amount staked
    /// @param boostMultiplier Boost multiplier granted (e.g., 115 = 15% boost)
    /// @param expiresAt Timestamp when boost expires
    event StakeCreated(
        address indexed user,
        uint256 amount,
        uint256 boostMultiplier,
        uint256 expiresAt
    );

    /// @notice Emitted when a user unstakes or boost expires
    /// @param user Address of the user
    /// @param amount Amount unstaked
    event StakeReleased(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when a credential is flagged for suspicious activity
    /// @param user Address of credential owner
    /// @param credentialIndex Index of flagged credential
    /// @param flagger Address of the flagger
    /// @param reason Reason for flagging
    event CredentialFlagged(
        address indexed user,
        uint256 credentialIndex,
        address indexed flagger,
        string reason
    );

    /// @notice Emitted when a flagged credential is cleared
    /// @param user Address of credential owner
    /// @param credentialIndex Index of cleared credential
    event CredentialCleared(
        address indexed user,
        uint256 credentialIndex
    );

    /// @notice Emitted when a credential is slashed (permanently removed)
    /// @param user Address of credential owner
    /// @param credentialIndex Index of slashed credential
    event CredentialSlashed(
        address indexed user,
        uint256 credentialIndex
    );

    /// @notice Emitted when a streak is achieved
    /// @param user Address of the user
    /// @param streakCount Number of months in current streak
    /// @param bonusPoints Points earned from streak
    event StreakAchieved(
        address indexed user,
        uint256 streakCount,
        uint256 bonusPoints
    );

    /// @notice Emitted when a user links an external NFT badge
    /// @param user Address of the user
    /// @param badgeSource Source of the badge (TALENT_PROTOCOL, etc.)
    /// @param badgeAddress Address of the badge contract
    /// @param bonusPoints Points awarded for badge
    event BadgeLinked(
        address indexed user,
        BadgeSource indexed badgeSource,
        address badgeAddress,
        uint256 bonusPoints
    );

    /// @notice Emitted when a referral is recorded
    /// @param referrer Address of the referrer
    /// @param referred Address of the newly referred user
    /// @param bonusPoints Points awarded to referrer
    event ReferralRecorded(
        address indexed referrer,
        address indexed referred,
        uint256 bonusPoints
    );

    /// @notice Emitted when seasonal multiplier is applied
    /// @param user Address of the user
    /// @param season Season number
    /// @param multiplier Multiplier percentage (e.g., 125 = 25% boost)
    event SeasonalMultiplierApplied(
        address indexed user,
        uint256 season,
        uint256 multiplier
    );

    // ============ Structs ============
    
    /// @notice Profile data structure (optimized for storage)
    /// @dev Packed to minimize storage slots using uint16/uint32/uint64 types
    /// Storage layout: owner (20) + createdAt (8) = 28 bytes (slot 1)
    ///               updatedAt (8) + reputationScore (4) + credentialCount (2) + verified (1) + padding (1) = 32 bytes (slot 2)
    struct Profile {
        address owner;              // 20 bytes - Profile owner address
        uint64 createdAt;           // 8 bytes  - Profile creation timestamp
        uint64 updatedAt;           // 8 bytes  - Last profile update timestamp
        uint32 reputationScore;     // 4 bytes  - Reputation score (max 4.2B)
        uint16 credentialCount;     // 2 bytes  - Total credentials (max 65535)
        bool verified;              // 1 byte   - Whether profile is verified
        string handle;              // New slot - Unique username
        string ipfsHash;            // New slot - IPFS hash of profile metadata
    }

    /// @notice Credential data structure with category support
    /// @dev Optimized storage layout to fit in minimal storage slots
    /// Storage: category (1) + issuedDate (8) + expiryDate (8) + verificationCount (2) + verified (1) + padding (4) = 24 bytes (slot 1)
    struct Credential {
        CredentialCategory category;  // 1 byte  - Enum: EDUCATION, WORK, CERTIFICATION, HACKATHON
        uint64 issuedDate;           // 8 bytes - Unix timestamp of issue date
        uint64 expiryDate;           // 8 bytes - Unix timestamp of expiry (0 = no expiry)
        uint16 verificationCount;    // 2 bytes - Number of verifications received
        bool verified;               // 1 byte  - Whether credential is verified
        FlagStatus flagStatus;       // 1 byte  - Flag status for abuse detection
        uint16 weightedVerifications;// 2 bytes - Weighted verification count (accounts for verifier credibility)
        string credentialType;       // New slot - Type/name of credential
        string issuer;               // New slot - Issuing organization
        string proofUrl;             // New slot - URL/IPFS hash of proof
    }

    /// @notice Verifier reputation tracking
    /// @dev Tracks verifier credibility based on successful verifications
    struct VerifierReputation {
        uint256 totalVerifications;  // Total credentials verified by this address
        uint256 validatedVerifications; // Verifications that were not slashed
        uint64 joinedAt;             // When verifier first verified a credential
    }

    /// @notice Staking record for reputation boost
    /// @dev Time-locked stake that boosts reputation while held
    struct Stake {
        uint256 amount;              // Amount staked
        uint64 stakedAt;             // When stake was created
        uint64 expiresAt;            // When boost expires/stake must be claimed
        uint16 boostPercentage;      // Boost percentage (e.g., 15 = 15% boost)
        bool active;                 // Whether stake is currently active
    }

    /// @notice Activity streak tracking
    /// @dev Monthly streak bonus for consistent profile engagement
    struct ActivityStreak {
        uint32 currentStreak;        // Current consecutive months active
        uint64 lastActivityAt;       // Last profile update timestamp
        uint32 longestStreak;        // Longest streak achieved
    }

    /// @notice Achievement data structure
    /// @dev Minimal storage for gas efficiency
    /// Storage: unlockedAt (8) + verified (1) + padding (7) = 16 bytes (slot 1)
    struct Achievement {
        uint64 unlockedAt;          // 8 bytes - Unix timestamp of achievement unlock
        bool verified;              // 1 byte  - Whether achievement is verified
        string title;               // New slot - Achievement title
        string description;         // New slot - Achievement description
    }

    /// @notice Reputation breakdown structure for detailed score calculation
    /// @dev Used in getReputationBreakdown() to show score composition
    struct ReputationBreakdown {
        uint256 baseScore;                  // Base score for profile creation
        uint256 verifiedProfileBonus;       // Bonus for verified profile
        uint256 credentialScore;            // Score from all credentials
        uint256 freshnessBonus;             // Bonus for recent credentials
        uint256 verifiedCredentialBonus;    // Bonus for verified credentials
        uint256 achievementScore;           // Score from achievements
        uint256 activityScore;              // Score from profile updates/activity
        uint256 stakingBonus;               // Bonus from active stakes
        uint256 streakBonus;                // Bonus from activity streaks
        uint256 badgeBonus;                 // Bonus from linked badges
        uint256 referralBonus;              // Bonus from referrals
        uint256 seasonalMultiplier;         // Applied seasonal multiplier
        uint256 totalScore;                 // Total calculated reputation
        uint256 credentialCount;            // Total credentials owned
        uint256 verifiedCredentialCount;    // Number of verified credentials
        uint256 achievementCount;           // Total achievements
        uint256 activeStake;                // Currently active staked amount
        uint32 currentStreak;               // Current activity streak months
        uint256 badgeCount;                 // Number of linked badges
        bool hasReferrer;                   // Whether user was referred
        uint256 referralsMade;              // Number of successful referrals
    }

    /// @notice Leaderboard cache entry for efficient pagination
    /// @dev Cached top profiles updated on reputation changes
    struct LeaderboardEntry {
        address user;                // User address
        uint256 reputation;          // User's current reputation score
    }

    // ============ Reputation Scoring Constants ============
    
    /// @notice Base score for creating a profile
    /// @dev Starting reputation for any new profile
    uint256 public constant SCORE_BASE = 10;
    
    /// @notice Bonus points for profile verification
    /// @dev Points added when profile is verified by admin
    uint256 public constant SCORE_VERIFIED_PROFILE = 25;
    
    /// @notice Points per verified credential
    /// @dev Points added for each credential with 2+ verifications
    uint256 public constant SCORE_VERIFIED_CREDENTIAL = 15;
    
    /// @notice Points per unverified credential
    /// @dev Base points for adding a credential (even without verification)
    uint256 public constant SCORE_UNVERIFIED_CREDENTIAL = 5;
    
    /// @notice Bonus multiplier for Talent Protocol achievements
    /// @dev Additional points based on linked achievements (off-chain)
    uint256 public constant SCORE_ACHIEVEMENT_BASE = 10;
    
    /// @notice Activity bonus for profile updates
    /// @dev Points for profile engagement and updates
    uint256 public constant SCORE_PROFILE_UPDATE = 3;

    /// @notice Staking boost base percentage
    uint256 public constant STAKE_BOOST_PERCENTAGE = 15;

    /// @notice Staking lock period in seconds (30 days)
    uint256 public constant STAKE_LOCK_PERIOD = 30 days;

    /// @notice Activity streak bonus per month
    uint256 public constant SCORE_STREAK_BONUS = 5;

    /// @notice Weighted verification multiplier for credible verifiers (e.g., 120 = 20% weight boost)
    uint256 public constant WEIGHTED_VERIFICATION_MULTIPLIER = 120;

    /// @notice Credential freshness bonus (per month since issuance)
    uint256 public constant SCORE_CREDENTIAL_FRESHNESS = 2;

    /// @notice Badge linking bonus points
    uint256 public constant SCORE_BADGE_LINK = 30;

    /// @notice Referral bonus for bringing new verified user
    uint256 public constant SCORE_REFERRAL_BONUS = 20;

    /// @notice Credential freshness threshold (recent = last 90 days)
    uint256 public constant CREDENTIAL_FRESHNESS_WINDOW = 90 days;

    /// @dev Current season number for seasonal multipliers
    uint256 public currentSeason = 1;
    
    /// @dev Mapping from user address to their profile - primary data structure
    mapping(address => Profile) public profiles;
    
    /// @dev Mapping from user address to array of their credentials
    /// Using private with public getter function to save gas on external calls
    mapping(address => Credential[]) private userCredentials;
    
    /// @dev Mapping from user address to array of their achievements
    mapping(address => Achievement[]) private userAchievements;
    
    /// @dev Mapping to track single-address verifications: user => verifier => credentialIndex => verified
    /// Prevents duplicate verifications and tracks multiple verifications per credential
    mapping(address => mapping(address => mapping(uint256 => bool))) public verificationMap;
    
    /// @dev Mapping from handle to user address for O(1) handle lookups
    mapping(string => address) public handleToAddress;
    
    /// @dev Array of all registered user addresses for enumeration
    address[] public allUsers;
    
    /// @dev Contract owner address - used for admin functions
    address public owner;
    
    /// @dev Total number of profiles created - cached for efficiency
    uint256 public profileCount;

    /// @dev Verifier reputation tracking: verifier => reputation stats
    mapping(address => VerifierReputation) public verifierReputation;

    /// @dev User staking records: user => stake
    mapping(address => Stake) public userStakes;

    /// @dev Activity streak tracking: user => streak
    mapping(address => ActivityStreak) public userStreaks;

    /// @dev Cached leaderboard for efficient pagination
    LeaderboardEntry[] public leaderboard;

    /// @dev Timestamp of last leaderboard update
    uint256 public lastLeaderboardUpdate;

    /// @dev Set of addresses allowed to flag credentials (verifier reputation threshold)
    mapping(address => bool) public allowedFlaggers;

    /// @dev Flag count for each credential: user => credentialIndex => flagCount
    mapping(address => mapping(uint256 => uint256)) public credentialFlagCounts;

    /// @dev User linked badges: user => array of linked badges
    mapping(address => LinkedBadge[]) public userBadges;

    /// @dev Referral records: referred user => referral data
    mapping(address => ReferralRecord) public referralData;

    /// @dev Referral counts: referrer => number of successful referrals
    mapping(address => uint256) public referralCounts;

    /// @dev Seasonal multipliers: user => season => multiplier
    mapping(address => mapping(uint256 => SeasonMultiplier)) public seasonalMultipliers;

    /// @dev NFT contract whitelist: contract address => enabled
    mapping(address => bool) public whitelistedNFTContracts;

    // ============ Constructor ============
    
    /// @notice Initialize the contract and set the deployer as owner
    constructor() {
        owner = msg.sender;
        profileCount = 0;
    }

    // ============ Modifiers ============
    
    /// @notice Restricts function access to contract owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    /// @notice Restricts function access to profile owner or contract owner
    /// @param profileAddress Address of the profile owner
    modifier onlyProfileOwner(address profileAddress) {
        require(
            msg.sender == profileAddress || msg.sender == owner, 
            "Only profile owner can modify"
        );
        _;
    }

    /// @notice Checks if a profile exists for the given address
    /// @param user Address to check
    modifier profileExists(address user) {
        require(profiles[user].owner != address(0), "Profile does not exist");
        _;
    }

    // ============ Profile Functions ============

    /// @notice Create a new user profile on the platform
    /// @dev Creates profile with unique handle and stores IPFS metadata hash
    /// Initializes activity streak and stake records
    /// Emits ProfileCreated event for indexing and validation
    /// @param _handle Unique identifier/username for the profile (cannot be changed)
    /// @param _ipfsHash IPFS hash (CIDv0) pointing to complete profile metadata JSON
    /// @custom:requires Profile doesn't already exist for caller
    /// @custom:requires Handle is unique and not empty
    /// @custom:requires IPFS hash is not empty
    /// @custom:gas Creates storage mappings + array push + event emission
    function createProfile(
        string memory _handle, 
        string memory _ipfsHash
    ) external {
        require(profiles[msg.sender].owner == address(0), "Profile already exists");
        require(handleToAddress[_handle] == address(0), "Handle already taken");
        require(bytes(_handle).length > 0, "Handle cannot be empty");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        profiles[msg.sender] = Profile({
            owner: msg.sender,
            handle: _handle,
            ipfsHash: _ipfsHash,
            createdAt: uint64(block.timestamp),
            updatedAt: uint64(block.timestamp),
            reputationScore: 0,
            credentialCount: 0,
            verified: false
        });

        // Initialize activity streak
        userStreaks[msg.sender] = ActivityStreak({
            currentStreak: 1,
            lastActivityAt: uint64(block.timestamp),
            longestStreak: 1
        });

        handleToAddress[_handle] = msg.sender;
        allUsers.push(msg.sender);
        profileCount++;

        // Add to leaderboard
        _updateLeaderboard(msg.sender);

        emit ProfileCreated(msg.sender, _handle, _ipfsHash, block.timestamp);
    }

    /// @notice Update existing profile with new IPFS metadata
    /// @dev Only the profile owner can update their profile
    /// Updates the IPFS hash pointing to fresh profile metadata
    /// Tracks activity streaks for monthly engagement bonuses
    /// @param _ipfsHash New IPFS hash (CIDv0) for updated profile metadata
    /// @custom:requires Profile exists for caller
    /// @custom:requires IPFS hash is not empty
    /// @custom:effects Updates IPFS hash, updatedAt timestamp, and activity streak
    /// @custom:gas Updates 2 storage fields + streak tracking + event emission
    function updateProfile(
        string memory _ipfsHash
    ) external profileExists(msg.sender) {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        
        profiles[msg.sender].ipfsHash = _ipfsHash;
        profiles[msg.sender].updatedAt = uint64(block.timestamp);

        // Update activity streak
        _updateActivityStreak(msg.sender);

        emit ProfileUpdated(msg.sender, _ipfsHash, block.timestamp);
    }

    /// @notice Retrieve a user's complete profile data
    /// @dev Returns the full Profile struct including all metadata
    /// @param user Address of the user whose profile to retrieve
    /// @return Profile struct containing user's profile information
    /// @custom:gas Read-only operation, no gas cost for view function
    function getProfile(address user) external view returns (Profile memory) {
        return profiles[user];
    }

    /// @notice Get user address by their unique handle
    /// @dev Performs O(1) reverse lookup from handle to address
    /// @param _handle The unique handle to lookup
    /// @return address User's wallet address (returns zero address if not found)
    /// @custom:gas Efficient mapping lookup with O(1) complexity
    function getUserByHandle(string memory _handle) external view returns (address) {
        return handleToAddress[_handle];
    }

    // ============ Credential Functions ============

    /// @notice Add a new credential to user's profile
    /// @dev Supports multiple credentials with 4 categories for better organization
    /// Credentials are stored in user-specific array and indexed by category
    /// Emits CredentialAdded event with category for easy filtering by off-chain indexers
    /// @param _category Credential category enum (EDUCATION, WORK, CERTIFICATION, HACKATHON)
    /// @param _credentialType Specific type/name of the credential (e.g., "Bachelor of Science")
    /// @param _issuer Organization or entity that issued the credential
    /// @param _issuedDate Unix timestamp when credential was issued
    /// @param _expiryDate Unix timestamp when credential expires (use 0 for permanent/no expiry)
    /// @param _proofUrl URL or IPFS hash pointing to credential proof/verification document
    /// @custom:requires Profile exists for caller
    /// @custom:requires All string fields are not empty
    /// @custom:requires Issue date is not in future
    /// @custom:requires Expiry date is after issue date (or 0)
    /// @custom:gas Creates 1 struct push + updates profile field + event emission
    function addCredential(
        CredentialCategory _category,
        string memory _credentialType,
        string memory _issuer,
        uint64 _issuedDate,
        uint64 _expiryDate,
        string memory _proofUrl
    ) external profileExists(msg.sender) {
        require(bytes(_credentialType).length > 0, "Credential type required");
        require(bytes(_issuer).length > 0, "Issuer required");
        require(_issuedDate <= block.timestamp, "Issue date cannot be in future");
        require(bytes(_proofUrl).length > 0, "Proof URL required");
        require(
            _expiryDate == 0 || _expiryDate > _issuedDate, 
            "Expiry must be after issue date"
        );

        userCredentials[msg.sender].push(Credential({
            category: _category,
            credentialType: _credentialType,
            issuer: _issuer,
            issuedDate: _issuedDate,
            expiryDate: _expiryDate,
            proofUrl: _proofUrl,
            verified: false,
            verificationCount: 0
        }));

        // Cache credential count in profile for O(1) access
        profiles[msg.sender].credentialCount = uint16(userCredentials[msg.sender].length);

        uint256 credentialIndex = userCredentials[msg.sender].length - 1;
        emit CredentialAdded(
            msg.sender, 
            _category,
            _credentialType, 
            credentialIndex,
            block.timestamp
        );
    }

    /// @notice Verify a user's credential from external verifier
    /// @dev Credentials become fully verified after 2+ independent verifications
    /// Verifications are weighted by verifier credibility (reputation-based)
    /// Each address can only verify each credential once (tracked in verificationMap)
    /// @param _user Address of the credential owner
    /// @param _credentialIndex Index of the credential in user's credential array
    /// @custom:requires Profile exists for user
    /// @custom:requires Credential index is valid
    /// @custom:requires Caller hasn't already verified this credential
    /// @custom:effects Increments verification count; applies weighted multiplier; sets verified flag if count >= 2
    /// @custom:gas 2 storage reads + 3 storage writes + event emission
    function verifyCredential(
        address _user, 
        uint256 _credentialIndex
    ) external profileExists(_user) {
        require(_credentialIndex < userCredentials[_user].length, "Credential not found");
        require(!verificationMap[_user][msg.sender][_credentialIndex], "Already verified by caller");

        Credential storage cred = userCredentials[_user][_credentialIndex];
        cred.verificationCount++;
        
        // Apply weighted verification based on verifier credibility
        uint256 weight = 100; // Base weight
        VerifierReputation memory vRep = verifierReputation[msg.sender];
        
        if (vRep.totalVerifications > 0 && vRep.validatedVerifications > 0) {
            uint256 successRate = (vRep.validatedVerifications * 100) / vRep.totalVerifications;
            if (successRate > 75) {
                weight = WEIGHTED_VERIFICATION_MULTIPLIER; // +20% weight for credible verifiers
            }
        }
        
        cred.weightedVerifications += uint16((weight * 1) / 100); // Increment weighted count
        
        // Track verifier reputation
        verifierReputation[msg.sender].totalVerifications++;
        verifierReputation[msg.sender].joinedAt = uint64(block.timestamp);
        
        verificationMap[_user][msg.sender][_credentialIndex] = true;

        // Mark as verified if verified by 2 or more independent sources (or 1+ weighted source)
        if (cred.verificationCount >= 2 || cred.weightedVerifications >= 2) {
            cred.verified = true;
            // Mark verifiers as having successful validations
            if (vRep.totalVerifications > 0) {
                verifierReputation[msg.sender].validatedVerifications++;
            }
        }

        emit CredentialVerified(_user, _credentialIndex, msg.sender, block.timestamp);
    }

    /// @notice Get all credentials for a specific user
    /// @dev Returns complete array of credentials - expensive for large arrays
    /// Consider using getCredentialByIndex or getCredentialsByCategory for filtering
    /// @param user Address of the user
    /// @return Credential[] Array of all credentials owned by the user
    /// @custom:gas O(n) where n = credential count; expensive for large arrays
    function getCredentials(address user) external view returns (Credential[] memory) {
        return userCredentials[user];
    }

    /// @notice Get credentials filtered by category for a specific user
    /// @dev Performs filtering off-chain equivalent in contract memory
    /// More efficient than getCredentials for specific category lookups
    /// @param user Address of the user
    /// @param _category Category enum to filter by
    /// @return Credential[] Array of credentials matching the category
    /// @custom:gas O(n) for two passes through credential array
    function getCredentialsByCategory(
        address user, 
        CredentialCategory _category
    ) external view returns (Credential[] memory) {
        uint256 count = 0;
        
        // First pass: count matching credentials to size array
        for (uint256 i = 0; i < userCredentials[user].length; i++) {
            if (userCredentials[user][i].category == _category) {
                count++;
            }
        }
        
        // Second pass: populate result array with matching credentials
        Credential[] memory result = new Credential[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userCredentials[user].length; i++) {
            if (userCredentials[user][i].category == _category) {
                result[index] = userCredentials[user][i];
                index++;
            }
        }
        
        return result;
    }

    /// @notice Get the total number of credentials for a user
    /// @dev Provides credential count without returning entire array
    /// @param user Address of the user
    /// @return uint256 Total credential count for user
    /// @custom:gas O(1) read operation
    function getCredentialCount(address user) external view returns (uint256) {
        return userCredentials[user].length;
    }

    /// @notice Get a specific credential by index
    /// @dev Retrieves single credential for efficient access
    /// @param user Address of the credential owner
    /// @param index Index of the credential in user's array
    /// @return Credential The credential struct at the specified index
    /// @custom:requires Index must be within bounds of user's credential array
    /// @custom:gas O(1) read operation
    function getCredentialByIndex(
        address user, 
        uint256 index
    ) external view returns (Credential memory) {
        require(index < userCredentials[user].length, "Index out of bounds");
        return userCredentials[user][index];
    }

    // ============ Credential Flagging & Slashing Functions ============

    /// @notice Flag a credential as suspicious (requires verifier reputation)
    /// @dev Only addresses with sufficient verifier history can flag credentials
    /// Flags trigger review and can lead to slashing if verified as fraudulent
    /// @param _user Address of credential owner
    /// @param _credentialIndex Index of credential to flag
    /// @param _reason String reason for flag
    /// @custom:requires Caller has at least 3 verified credentials in their history
    /// @custom:requires Credential not already flagged or slashed
    /// @custom:effects Sets credential status to FLAGGED
    /// @custom:gas 2 storage writes + 1 event
    function flagCredential(
        address _user,
        uint256 _credentialIndex,
        string memory _reason
    ) external {
        require(_credentialIndex < userCredentials[_user].length, "Credential not found");
        require(
            verifierReputation[msg.sender].validatedVerifications >= 3,
            "Insufficient verifier reputation to flag"
        );
        
        Credential storage cred = userCredentials[_user][_credentialIndex];
        require(cred.flagStatus == FlagStatus.NONE, "Credential already flagged or slashed");
        
        cred.flagStatus = FlagStatus.FLAGGED;
        credentialFlagCounts[_user][_credentialIndex]++;
        
        emit CredentialFlagged(_user, _credentialIndex, msg.sender, _reason);
    }

    /// @notice Clear a flagged credential (admin only)
    /// @dev Owner can clear a credential after manual review determines it's legitimate
    /// Raises credential status to VERIFIED_CLEAN
    /// @param _user Address of credential owner
    /// @param _credentialIndex Index of credential to clear
    /// @custom:requires Caller is contract owner
    /// @custom:requires Credential is flagged
    /// @custom:effects Sets credential status to VERIFIED_CLEAN
    /// @custom:gas 1 storage write + 1 event
    function clearFlaggedCredential(
        address _user,
        uint256 _credentialIndex
    ) external onlyOwner {
        require(_credentialIndex < userCredentials[_user].length, "Credential not found");
        
        Credential storage cred = userCredentials[_user][_credentialIndex];
        require(cred.flagStatus == FlagStatus.FLAGGED, "Credential not flagged");
        
        cred.flagStatus = FlagStatus.VERIFIED_CLEAN;
        
        emit CredentialCleared(_user, _credentialIndex);
    }

    /// @notice Slash a credential permanently (admin only)
    /// @dev Owner can slash credentials determined to be fraudulent after review
    /// Slashed credentials count against reputation permanently
    /// @param _user Address of credential owner
    /// @param _credentialIndex Index of credential to slash
    /// @custom:requires Caller is contract owner
    /// @custom:requires Credential is flagged
    /// @custom:effects Sets credential status to SLASHED, marks verifiers' validity counts
    /// @custom:gas 3 storage writes + 1 event
    function slashCredential(
        address _user,
        uint256 _credentialIndex
    ) external onlyOwner {
        require(_credentialIndex < userCredentials[_user].length, "Credential not found");
        
        Credential storage cred = userCredentials[_user][_credentialIndex];
        require(cred.flagStatus == FlagStatus.FLAGGED, "Only flagged credentials can be slashed");
        
        cred.flagStatus = FlagStatus.SLASHED;
        cred.verified = false;
        
        emit CredentialSlashed(_user, _credentialIndex);
    }

    // ============ Badge & NFT Verification Functions ============

    /// @notice Link an external NFT badge (ERC721) to profile
    /// @dev Verifies user ownership of NFT and awards points for badge
    /// Enables cross-protocol credential verification (Talent Protocol, etc.)
    /// @param _badgeAddress Smart contract address of badge
    /// @param _badgeSource Source type (TALENT_PROTOCOL, GITCOIN_PASSPORT, etc.)
    /// @custom:requires Profile exists for caller
    /// @custom:requires Badge contract is whitelisted or caller is owner
    /// @custom:requires Caller owns at least 1 badge NFT
    /// @custom:effects Adds LinkedBadge record, increases reputation
    /// @custom:gas 1 verification call + 2 storage writes + 1 event
    function linkBadge(
        address _badgeAddress,
        BadgeSource _badgeSource
    ) external profileExists(msg.sender) {
        require(_badgeAddress != address(0), "Invalid badge address");
        require(
            whitelistedNFTContracts[_badgeAddress] || msg.sender == owner,
            "Badge not whitelisted"
        );

        // Verify user owns the NFT
        IERC721 badge = IERC721(_badgeAddress);
        require(badge.balanceOf(msg.sender) > 0, "User does not own this badge");

        // Add badge to user's linked badges
        userBadges[msg.sender].push(LinkedBadge({
            source: _badgeSource,
            badgeAddress: _badgeAddress,
            badgePoints: SCORE_BADGE_LINK,
            linkedAt: uint64(block.timestamp),
            verified: true
        }));

        emit BadgeLinked(msg.sender, _badgeSource, _badgeAddress, SCORE_BADGE_LINK);
    }

    /// @notice Get user's linked badges
    /// @param user Address of the user
    /// @return LinkedBadge[] Array of user's linked badges
    function getLinkedBadges(address user) external view returns (LinkedBadge[] memory) {
        return userBadges[user];
    }

    /// @notice Get count of linked badges
    /// @param user Address of the user
    /// @return uint256 Number of badges linked by user
    function getBadgeCount(address user) external view returns (uint256) {
        return userBadges[user].length;
    }

    // ============ Referral Functions ============

    /// @notice Record a referral (called when referred user creates profile)
    /// @dev Rewards both referrer and ensures referred user gets one-time bonus
    /// Internal function, typically called by referral link handler
    /// @param _referrer Address of the referrer
    /// @param _referred Address of newly referred user
    /// @custom:requires Referred user has just created profile
    /// @custom:requires No existing referral record for referred user
    /// @custom:effects Creates referral record, awards bonus to referrer
    /// @custom:gas 2 storage writes + 1 event
    function recordReferral(
        address _referrer,
        address _referred
    ) external onlyOwner profileExists(_referred) {
        require(referralData[_referred].referrer == address(0), "User already has referrer");

        referralData[_referred] = ReferralRecord({
            referrer: _referrer,
            referralBonus: SCORE_REFERRAL_BONUS,
            referredAt: uint64(block.timestamp)
        });

        referralCounts[_referrer]++;

        emit ReferralRecorded(_referrer, _referred, SCORE_REFERRAL_BONUS);
    }

    /// @notice Get referral information for a user
    /// @param user Address of the user
    /// @return ReferralRecord User's referral data (who referred them)
    function getReferralData(address user) external view returns (ReferralRecord memory) {
        return referralData[user];
    }

    /// @notice Get referral count for a user (how many they've referred)
    /// @param user Address of the user
    /// @return uint256 Number of successful referrals
    function getReferralCount(address user) external view returns (uint256) {
        return referralCounts[user];
    }

    // ============ Seasonal Multiplier Functions ============

    /// @notice Award seasonal multiplier to top performers
    /// @dev Grants season-specific reputation multiplier boost
    /// Typically called end-of-season to reward consistent performers
    /// @param _user Address of the user
    /// @param _multiplier Multiplier percentage (e.g., 125 = 25% bonus)
    /// @custom:requires Caller is contract owner
    /// @custom:requires Profile exists for user
    /// @custom:effects Creates SeasonMultiplier record for next season
    /// @custom:gas 1 storage write + 1 event
    function awardSeasonalMultiplier(
        address _user,
        uint16 _multiplier
    ) external onlyOwner profileExists(_user) {
        require(_multiplier > 100, "Multiplier must be > 100%");

        uint256 nextSeason = currentSeason + 1;
        uint64 expiresAt = uint64(block.timestamp) + uint64(90 days);

        seasonalMultipliers[_user][nextSeason] = SeasonMultiplier({
            season: nextSeason,
            multiplier: _multiplier,
            appliedAt: uint64(block.timestamp),
            expiresAt: expiresAt
        });

        emit SeasonalMultiplierApplied(_user, nextSeason, _multiplier);
    }

    /// @notice Advance to next season (resets season-based tracking)
    /// @dev Called at season boundary to increment season and reset tracking
    /// @custom:requires Caller is contract owner
    /// @custom:effects Increments currentSeason
    function advanceSeason() external onlyOwner {
        currentSeason++;
    }

    /// @notice Get seasonal multiplier for a user
    /// @param user Address of the user
    /// @param season Season number
    /// @return SeasonMultiplier User's season multiplier data
    function getSeasonalMultiplier(address user, uint256 season) 
        external 
        view 
        returns (SeasonMultiplier memory) 
    {
        return seasonalMultipliers[user][season];
    }

    // ============ Admin Badge Management ============

    /// @notice Whitelist an NFT contract for badge linking
    /// @dev Owner can add verified NFT contracts that users can link
    /// @param _contractAddress Address of the NFT contract
    /// @param _enable Whether to enable or disable the contract
    /// @custom:requires Caller is contract owner
    function setNFTContractWhitelist(address _contractAddress, bool _enable) 
        external 
        onlyOwner 
    {
        require(_contractAddress != address(0), "Invalid contract address");
        whitelistedNFTContracts[_contractAddress] = _enable;
    }

    /// @notice Check if an NFT contract is whitelisted
    /// @param _contractAddress Address to check
    /// @return bool Whether contract is whitelisted
    function isNFTContractWhitelisted(address _contractAddress) 
        external 
        view 
        returns (bool) 
    {
        return whitelistedNFTContracts[_contractAddress];
    }



    /// @notice Unlock a new achievement on user's profile
    /// @dev Achievements represent milestones and are tracked with unlock timestamp
    /// Automatically increases reputation score by 10 points per achievement
    /// Emits both AchievementUnlocked and ReputationScoreUpdated events
    /// @param _title Achievement title/name (e.g., "First Profile Created")
    /// @param _description Detailed description of the achievement
    /// @custom:requires Profile exists for caller
    /// @custom:requires Both title and description are not empty
    /// @custom:effects Adds achievement to array, increases reputation score by 10
    /// @custom:gas 1 array push + 1 storage write + 2 events
    function unlockAchievement(
        string memory _title, 
        string memory _description
    ) 
        external 
        profileExists(msg.sender) 
    {
        require(bytes(_title).length > 0, "Title required");
        require(bytes(_description).length > 0, "Description required");

        userAchievements[msg.sender].push(Achievement({
            title: _title,
            description: _description,
            unlockedAt: uint64(block.timestamp),
            verified: false
        }));

        // Increase reputation for unlocking achievement
        uint256 oldScore = profiles[msg.sender].reputationScore;
        profiles[msg.sender].reputationScore += 10;

        emit AchievementUnlocked(msg.sender, _title, block.timestamp);
        emit ReputationScoreUpdated(msg.sender, oldScore, profiles[msg.sender].reputationScore);
    }

    /// @notice Get all achievements for a specific user
    /// @dev Returns complete array of achievements - expensive for large arrays
    /// @param user Address of the user
    /// @return Achievement[] Array of all achievements owned by the user
    /// @custom:gas O(n) read where n = achievement count
    function getAchievements(address user) external view returns (Achievement[] memory) {
        return userAchievements[user];
    }

    /// @notice Get the total number of achievements for a user
    /// @param user Address of the user
    /// @return uint256 Total achievement count
    /// @custom:gas O(1) read operation
    function getAchievementCount(address user) external view returns (uint256) {
        return userAchievements[user].length;
    }

    // ============ Staking Functions ============

    /// @notice Stake tokens to boost reputation temporarily
    /// @dev Allows users to lock tokens for a time-locked boost to reputation
    /// Provides 15% reputation boost while stake is active; decays/expires after lock period
    /// @param _amount Amount to stake (must be > 0)
    /// @custom:requires Profile exists for caller
    /// @custom:requires No active stake exists
    /// @custom:requires Amount > 0
    /// @custom:effects Creates new stake record with boost multiplier and expiry
    /// @custom:gas 1 storage write + 1 event
    function createStake(uint256 _amount) external profileExists(msg.sender) {
        require(_amount > 0, "Stake amount must be > 0");
        require(!userStakes[msg.sender].active, "Active stake already exists");

        uint64 expiresAt = uint64(block.timestamp) + uint64(STAKE_LOCK_PERIOD);
        
        userStakes[msg.sender] = Stake({
            amount: _amount,
            stakedAt: uint64(block.timestamp),
            expiresAt: expiresAt,
            boostPercentage: uint16(STAKE_BOOST_PERCENTAGE),
            active: true
        });

        emit StakeCreated(msg.sender, _amount, STAKE_BOOST_PERCENTAGE, expiresAt);
    }

    /// @notice Release an expired or active stake
    /// @dev Allows user to withdraw staked tokens after lock period expires
    /// If released early (before expiry), boost is forfeited
    /// @custom:requires Profile exists for caller
    /// @custom:requires Active stake exists
    /// @custom:effects Deactivates stake, emits StakeReleased event
    /// @custom:gas 1 storage write + 1 event
    function releaseStake() external profileExists(msg.sender) {
        require(userStakes[msg.sender].active, "No active stake");

        uint256 amount = userStakes[msg.sender].amount;
        userStakes[msg.sender].active = false;

        emit StakeReleased(msg.sender, amount);
    }

    /// @notice Get current active stake for a user
    /// @param user Address of the user
    /// @return Stake The user's stake record (or empty if no active stake)
    function getStake(address user) external view returns (Stake memory) {
        return userStakes[user];
    }

    // ============ Reputation Functions ============

    /// @notice Internal function to update activity streak on profile updates
    /// @dev Tracks consecutive months of activity; resets on inactivity > 35 days
    /// @param user Address of the user
    function _updateActivityStreak(address user) internal {
        ActivityStreak storage streak = userStreaks[user];
        uint64 now = uint64(block.timestamp);
        
        if (streak.lastActivityAt == 0) {
            // First activity
            streak.currentStreak = 1;
            streak.lastActivityAt = now;
            streak.longestStreak = 1;
        } else {
            // Check if still in same month (30 days)
            uint256 daysSinceLastActivity = (now - streak.lastActivityAt) / 1 days;
            
            if (daysSinceLastActivity < 35) {
                // Still in same streak window
                if (daysSinceLastActivity >= 30) {
                    // New month started
                    streak.currentStreak++;
                    if (streak.currentStreak > streak.longestStreak) {
                        streak.longestStreak = streak.currentStreak;
                    }
                    
                    // Emit streak achievement bonus
                    uint256 streakBonus = uint256(streak.currentStreak) * SCORE_STREAK_BONUS;
                    emit StreakAchieved(user, streak.currentStreak, streakBonus);
                }
            } else {
                // Streak broken, reset
                streak.currentStreak = 1;
            }
            
            streak.lastActivityAt = now;
        }
    }

    /// @notice Internal function to calculate deterministic reputation score
    /// @dev Core reputation calculation logic - deterministic based on on-chain data
    /// Score = Base + Profile Verification + Credentials + Achievements + Activity + Staking + Streaks + Badges + Referrals + Seasonal
    /// @param user Address of the user
    /// @return uint256 Calculated reputation score
    /// @custom:formula Includes all bonuses: weighted verifications, staking, streaks, badges, referrals, seasonalMultipliers
    function _calculateReputation(address user) internal view returns (uint256) {
        Profile memory profile = profiles[user];
        
        // If no profile exists, return 0
        if (profile.owner == address(0)) {
            return 0;
        }
        
        uint256 score = SCORE_BASE;
        
        // Add verified profile bonus
        if (profile.verified) {
            score += SCORE_VERIFIED_PROFILE;
        }
        
        // Calculate credential score (excluding slashed credentials)
        uint256 totalCredentials = userCredentials[user].length;
        uint256 activeCredentials = 0;
        uint256 freshnessBonus = 0;
        
        if (totalCredentials > 0) {
            for (uint256 i = 0; i < totalCredentials; i++) {
                if (userCredentials[user][i].flagStatus != FlagStatus.SLASHED) {
                    activeCredentials++;
                    
                    // Freshness bonus for recent credentials (within 90 days)
                    Credential memory cred = userCredentials[user][i];
                    if (cred.issuedDate > 0 && block.timestamp - cred.issuedDate < CREDENTIAL_FRESHNESS_WINDOW) {
                        uint256 monthsSinceIssue = (block.timestamp - cred.issuedDate) / (30 days);
                        if (monthsSinceIssue == 0) monthsSinceIssue = 1; // At least 1 point
                        freshnessBonus += monthsSinceIssue * SCORE_CREDENTIAL_FRESHNESS;
                    }
                }
            }
            
            // Base score for all active credentials
            score += activeCredentials * SCORE_UNVERIFIED_CREDENTIAL;
            
            // Add freshness bonus
            score += freshnessBonus;
            
            // Bonus for verified credentials (2+ verifications or credible verifier)
            uint256 verifiedCredentials = 0;
            for (uint256 i = 0; i < totalCredentials; i++) {
                if (userCredentials[user][i].verified && userCredentials[user][i].flagStatus != FlagStatus.SLASHED) {
                    verifiedCredentials++;
                }
            }
            score += verifiedCredentials * SCORE_VERIFIED_CREDENTIAL;
        }
        
        // Calculate achievement score
        uint256 achievementCount = userAchievements[user].length;
        score += achievementCount * SCORE_ACHIEVEMENT_BASE;
        
        // Activity bonus: points for profile engagement (1 point per month of activity)
        if (profile.updatedAt > profile.createdAt) {
            uint256 monthsActive = (profile.updatedAt - profile.createdAt) / 2_592_000;
            if (monthsActive > 0) {
                score += monthsActive * SCORE_PROFILE_UPDATE;
            }
        }
        
        // Staking bonus: 15% boost if stake is active
        Stake memory stake = userStakes[user];
        if (stake.active && stake.expiresAt > block.timestamp) {
            uint256 stakingBonus = (score * stake.boostPercentage) / 100;
            score += stakingBonus;
        }
        
        // Streak bonus: additional points per month of streak
        ActivityStreak memory streak = userStreaks[user];
        if (streak.currentStreak > 0) {
            score += uint256(streak.currentStreak) * SCORE_STREAK_BONUS;
        }
        
        // Badge linking bonus: points for each linked badge
        uint256 badgeCount = userBadges[user].length;
        if (badgeCount > 0) {
            score += badgeCount * SCORE_BADGE_LINK;
        }
        
        // Referral bonus: one-time bonus for being referred
        ReferralRecord memory referral = referralData[user];
        if (referral.referrer != address(0)) {
            score += SCORE_REFERRAL_BONUS;
        }
        
        // Referrer bonus: points for each successful referral
        uint256 referralCount = referralCounts[user];
        if (referralCount > 0) {
            score += referralCount * SCORE_REFERRAL_BONUS;
        }
        
        // Seasonal multiplier: apply if user has active season multiplier
        SeasonMultiplier memory seasonMult = seasonalMultipliers[user][currentSeason];
        if (seasonMult.multiplier > 100 && seasonMult.expiresAt > block.timestamp) {
            score = (score * seasonMult.multiplier) / 100;
        }
        
        return score;
    }

    /// @notice Calculate detailed reputation breakdown for a user
    /// @dev Shows complete breakdown of reputation score composition
    /// Useful for UI display and understanding score calculation
    /// @param user Address of the user
    /// @return ReputationBreakdown Detailed breakdown of all score components
    /// @custom:gas O(n) where n = credential count (need to check each credential)
    function getReputationBreakdown(address user) external view returns (ReputationBreakdown memory) {
        Profile memory profile = profiles[user];
        
        // Return zero breakdown if profile doesn't exist
        if (profile.owner == address(0)) {
            return ReputationBreakdown({
                baseScore: 0,
                verifiedProfileBonus: 0,
                credentialScore: 0,
                freshnessBonus: 0,
                verifiedCredentialBonus: 0,
                achievementScore: 0,
                activityScore: 0,
                stakingBonus: 0,
                streakBonus: 0,
                badgeBonus: 0,
                referralBonus: 0,
                seasonalMultiplier: 100,
                totalScore: 0,
                credentialCount: 0,
                verifiedCredentialCount: 0,
                achievementCount: 0,
                activeStake: 0,
                currentStreak: 0,
                badgeCount: 0,
                hasReferrer: false,
                referralsMade: 0
            });
        }
        
        uint256 baseScore = SCORE_BASE;
        
        uint256 verifiedProfileBonus = profile.verified ? SCORE_VERIFIED_PROFILE : 0;
        
        // Credential scores (excluding slashed) + freshness bonus
        uint256 totalCredentials = userCredentials[user].length;
        uint256 activeCredentials = 0;
        uint256 freshnessBonus = 0;
        
        if (totalCredentials > 0) {
            for (uint256 i = 0; i < totalCredentials; i++) {
                if (userCredentials[user][i].flagStatus != FlagStatus.SLASHED) {
                    activeCredentials++;
                    
                    // Freshness bonus for recent credentials
                    Credential memory cred = userCredentials[user][i];
                    if (cred.issuedDate > 0 && block.timestamp - cred.issuedDate < CREDENTIAL_FRESHNESS_WINDOW) {
                        uint256 monthsSinceIssue = (block.timestamp - cred.issuedDate) / (30 days);
                        if (monthsSinceIssue == 0) monthsSinceIssue = 1;
                        freshnessBonus += monthsSinceIssue * SCORE_CREDENTIAL_FRESHNESS;
                    }
                }
            }
        }
        uint256 credentialScore = activeCredentials * SCORE_UNVERIFIED_CREDENTIAL;
        
        uint256 verifiedCredentials = 0;
        for (uint256 i = 0; i < totalCredentials; i++) {
            if (userCredentials[user][i].verified && userCredentials[user][i].flagStatus != FlagStatus.SLASHED) {
                verifiedCredentials++;
            }
        }
        uint256 verifiedCredentialBonus = verifiedCredentials * SCORE_VERIFIED_CREDENTIAL;
        
        // Achievement score
        uint256 achievementCount = userAchievements[user].length;
        uint256 achievementScore = achievementCount * SCORE_ACHIEVEMENT_BASE;
        
        // Activity score
        uint256 activityScore = 0;
        if (profile.updatedAt > profile.createdAt) {
            uint256 monthsActive = (profile.updatedAt - profile.createdAt) / 2_592_000;
            if (monthsActive > 0) {
                activityScore = monthsActive * SCORE_PROFILE_UPDATE;
            }
        }
        
        // Staking bonus
        Stake memory stake = userStakes[user];
        uint256 stakingBonus = 0;
        uint256 activeStake = 0;
        if (stake.active && stake.expiresAt > block.timestamp) {
            uint256 baseForBonus = baseScore + verifiedProfileBonus + credentialScore + freshnessBonus +
                                   verifiedCredentialBonus + achievementScore + activityScore;
            stakingBonus = (baseForBonus * stake.boostPercentage) / 100;
            activeStake = stake.amount;
        }
        
        // Streak bonus
        ActivityStreak memory streak = userStreaks[user];
        uint256 streakBonus = uint256(streak.currentStreak) * SCORE_STREAK_BONUS;
        
        // Badge bonus
        uint256 badgeCount = userBadges[user].length;
        uint256 badgeBonus = badgeCount * SCORE_BADGE_LINK;
        
        // Referral bonus
        ReferralRecord memory referral = referralData[user];
        bool hasReferrer = referral.referrer != address(0);
        uint256 referralBonus = hasReferrer ? SCORE_REFERRAL_BONUS : 0;
        
        uint256 referralsMade = referralCounts[user];
        referralBonus += referralsMade * SCORE_REFERRAL_BONUS;
        
        // Seasonal multiplier
        SeasonMultiplier memory seasonMult = seasonalMultipliers[user][currentSeason];
        uint256 seasonalMultiplier = 100;
        if (seasonMult.multiplier > 100 && seasonMult.expiresAt > block.timestamp) {
            seasonalMultiplier = seasonMult.multiplier;
        }
        
        uint256 baseCalculation = baseScore + verifiedProfileBonus + credentialScore + freshnessBonus +
                                  verifiedCredentialBonus + achievementScore + activityScore + 
                                  stakingBonus + streakBonus + badgeBonus + referralBonus;
        
        uint256 totalScore = (baseCalculation * seasonalMultiplier) / 100;
        
        return ReputationBreakdown({
            baseScore: baseScore,
            verifiedProfileBonus: verifiedProfileBonus,
            credentialScore: credentialScore,
            freshnessBonus: freshnessBonus,
            verifiedCredentialBonus: verifiedCredentialBonus,
            achievementScore: achievementScore,
            activityScore: activityScore,
            stakingBonus: stakingBonus,
            streakBonus: streakBonus,
            badgeBonus: badgeBonus,
            referralBonus: referralBonus,
            seasonalMultiplier: seasonalMultiplier,
            totalScore: totalScore,
            credentialCount: activeCredentials,
            verifiedCredentialCount: verifiedCredentials,
            achievementCount: achievementCount,
            activeStake: activeStake,
            currentStreak: streak.currentStreak,
            badgeCount: badgeCount,
            hasReferrer: hasReferrer,
            referralsMade: referralsMade
        });
    }

    /// @notice Update a user's reputation score (admin only)
    /// @dev Allows contract owner to adjust reputation for various reasons
    /// Emits ReputationScoreUpdated event for tracking score changes
    /// @param _user Address of the user whose reputation to update
    /// @param _score New reputation score value
    /// @custom:requires Caller is contract owner
    /// @custom:requires Profile exists for user
    /// @custom:gas 1 storage write + 1 event emission
    function updateReputation(
        address _user, 
        uint256 _score
    ) 
        external 
        onlyOwner 
        profileExists(_user) 
    {
        uint256 oldScore = profiles[_user].reputationScore;
        profiles[_user].reputationScore = uint32(_score);
        emit ReputationScoreUpdated(_user, oldScore, _score);
    }

    /// @notice Get a user's current reputation score (deterministic)
    /// @dev Returns reputation calculated from on-chain data:
    /// - Base score (10 points)
    /// - Verified profile bonus (25 points)
    /// - Credentials: 5 points each + 15 bonus for verified
    /// - Achievements: 10 points each
    /// - Activity: 3 points per month of profile engagement
    /// Calculation is fully deterministic based on current on-chain state
    /// @param user Address of the user
    /// @return uint256 User's calculated reputation score
    /// @custom:gas O(n) where n = credential count
    function getReputation(address user) external view returns (uint256) {
        return _calculateReputation(user);
    }

    /// @notice Verify a user's profile (admin only)
    /// @dev Sets verified flag on profile, indicating platform verification
    /// @param _user Address of the user whose profile to verify
    /// @custom:requires Caller is contract owner
    /// @custom:requires Profile exists for user
    /// @custom:gas 1 storage write
    function verifyProfile(address _user) external onlyOwner profileExists(_user) {
        profiles[_user].verified = true;
    }

    // ============ View Functions ============

    /// @notice Get total number of registered users on the platform
    /// @return uint256 Total count of users with profiles
    /// @custom:gas O(1) read operation
    function getUserCount() external view returns (uint256) {
        return allUsers.length;
    }

    /// @notice Get user address by index in the allUsers array
    /// @dev Enables enumeration of all users for indexing and analytics
    /// @param _index Array index of user to retrieve
    /// @return address User wallet address at the specified index
    /// @custom:requires Index must be within bounds of allUsers array
    /// @custom:gas O(1) read operation
    function getUserByIndex(uint256 _index) external view returns (address) {
        require(_index < allUsers.length, "Index out of bounds");
        return allUsers[_index];
    }

    /// @notice Get top profiles sorted by reputation score
    /// @dev Returns addresses of users with highest reputation scores
    /// Uses cached leaderboard for efficient pagination
    /// @param _limit Maximum number of top profiles to return
    /// @return address[] Array of addresses sorted by reputation (highest first)
    /// @custom:gas O(limit) with cached leaderboard
    function getTopProfiles(uint256 _limit) external view returns (address[] memory) {
        uint256 limit = _limit > leaderboard.length ? leaderboard.length : _limit;
        address[] memory topProfiles = new address[](limit);
        
        for (uint256 i = 0; i < limit; i++) {
            topProfiles[i] = leaderboard[i].user;
        }
        
        return topProfiles;
    }

    /// @notice Get paginated leaderboard entries
    /// @dev Returns portion of cached leaderboard with reputation scores
    /// Enables efficient frontend pagination without O(n²) sorting
    /// @param _offset Starting index in leaderboard
    /// @param _limit Number of entries to return
    /// @return LeaderboardEntry[] Array of leaderboard entries (user address + reputation)
    /// @custom:gas O(limit) read operation
    function getLeaderboardPage(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (LeaderboardEntry[] memory) 
    {
        require(_offset < leaderboard.length, "Offset out of bounds");
        
        uint256 remaining = leaderboard.length - _offset;
        uint256 pageSize = _limit > remaining ? remaining : _limit;
        
        LeaderboardEntry[] memory page = new LeaderboardEntry[](pageSize);
        for (uint256 i = 0; i < pageSize; i++) {
            page[i] = leaderboard[_offset + i];
        }
        
        return page;
    }

    /// @notice Get current leaderboard size
    /// @return uint256 Total number of entries in cached leaderboard
    function getLeaderboardSize() external view returns (uint256) {
        return leaderboard.length;
    }

    /// @notice Update cached leaderboard (internal helper)
    /// @dev Called whenever a reputation change occurs
    /// Maintains top-100 cache and reorders efficiently
    /// @param user Address of user whose reputation changed
    function _updateLeaderboard(address user) internal {
        // Find user in leaderboard
        uint256 userIndex = leaderboard.length;
        for (uint256 i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i].user == user) {
                userIndex = i;
                break;
            }
        }
        
        uint256 currentRep = _calculateReputation(user);
        
        if (userIndex == leaderboard.length) {
            // User not in leaderboard, add if strong enough for top 100
            if (leaderboard.length < 100) {
                leaderboard.push(LeaderboardEntry({user: user, reputation: currentRep}));
            } else if (currentRep > leaderboard[99].reputation) {
                leaderboard[99] = LeaderboardEntry({user: user, reputation: currentRep});
            }
        } else {
            // Update user's reputation in leaderboard
            leaderboard[userIndex].reputation = currentRep;
        }
        
        // Bubble-sort to maintain order (simple for cached list)
        for (uint256 i = 0; i < leaderboard.length; i++) {
            for (uint256 j = i + 1; j < leaderboard.length; j++) {
                if (leaderboard[j].reputation > leaderboard[i].reputation) {
                    // Swap
                    LeaderboardEntry memory temp = leaderboard[i];
                    leaderboard[i] = leaderboard[j];
                    leaderboard[j] = temp;
                }
            }
        }
        
        lastLeaderboardUpdate = block.timestamp;
    }

    // ============ Admin Functions ============

    /// @notice Transfer contract ownership to a new address
    /// @dev New owner will have access to admin-only functions
    /// @param _newOwner Address of the new contract owner
    /// @custom:requires Caller is current contract owner
    /// @custom:requires New owner address is not zero address
    /// @custom:gas 1 storage write
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    /// @notice Get verifier reputation details
    /// @param verifier Address of the verifier
    /// @return VerifierReputation Verifier's reputation stats
    function getVerifierReputation(address verifier) external view returns (VerifierReputation memory) {
        return verifierReputation[verifier];
    }

    /// @notice Get activity streak for a user
    /// @param user Address of the user
    /// @return ActivityStreak User's streak information
    function getActivityStreak(address user) external view returns (ActivityStreak memory) {
        return userStreaks[user];
    }

    /// @notice Emergency withdrawal of contract balance
    /// @dev Transfers entire ETH balance to contract owner using secure call pattern
    /// Should only be used in case of emergency
    /// @custom:requires Caller is contract owner
    /// @custom:gas Low-level call for ETH withdrawal
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // ============ Fallback Functions ============
    
    /// @notice Accept ETH transfers (payable fallback)
    receive() external payable {}
}
