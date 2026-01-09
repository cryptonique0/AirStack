# AirStack V2 - Token Airdrop System on Base Blockchain

A comprehensive token airdrop system built with Solidity smart contracts for the Base blockchain (Ethereum L2).

## 🚀 New Features (V2 - Base Migration)

### Core Features (Preserved from V1)
- **ERC20 Token**: Full-featured fungible token with mint/burn capabilities
- **Airdrop Manager**: Efficient token distribution with batch operations
- **Whitelist System**: Tiered whitelist management with customizable allocations
- **Vesting Schedules**: Time-locked distributions with cliff periods and linear vesting
- **Governance DAO**: Community voting on proposals and parameter changes
- **Merkle Tree Verification**: Gas-efficient claim verification using merkle proofs

### New Base-Specific Features ⭐
- **Native ETH Airdrops**: Direct distribution of native ETH (not just tokens)
- **Multi-Airdrop Aggregator**: Claim from multiple campaigns in a single transaction
- **Advanced Analytics**: Real-time tracking of claims, participation rates, and token flow metrics
- **Gas Optimization**: Optimized for Base's low-cost environment
- **Improved Security**: ReentrancyGuard on all critical functions
- **Enhanced Events**: Comprehensive event logging for off-chain tracking

## Architecture

### Smart Contracts

| Contract | Purpose | Features |
|----------|---------|----------|
| `AirdropToken.sol` | ERC20 Token | Mint, burn, metadata management |
| `AirdropManager.sol` | Token Airdrops | Allocation, claiming, pause controls |
| `ETHAirdropManager.sol` | Native ETH Airdrops | ETH allocation and claiming (NEW) |
| `WhitelistManager.sol` | Eligibility Control | Tiered whitelist, batch operations |
| `VestingSchedule.sol` | Time-Locked Distribution | Cliff periods, linear vesting |
| `Governance.sol` | DAO & Voting | Proposals, voting, governance tokens |
| `MerkleTree.sol` | Proof Verification | Merkle proof-based claiming |
| `AirdropAggregator.sol` | Multi-Campaign Claiming | Aggregate claims from multiple airdrops (NEW) |
| `Analytics.sol` | Metrics & Tracking | Real-time claim statistics (NEW) |

## Project Structure

```
AirStack/
├── contracts/
│   ├── AirdropToken.sol           # ERC20 Token
│   ├── AirdropManager.sol         # Token Airdrop Management
│   ├── ETHAirdropManager.sol      # Native ETH Airdrops (NEW)
│   ├── WhitelistManager.sol       # Whitelist with Tiers
│   ├── VestingSchedule.sol        # Vesting with Cliff
│   ├── Governance.sol             # DAO Voting System
│   ├── MerkleTree.sol             # Merkle Proof Claims
│   ├── AirdropAggregator.sol      # Multi-Campaign Claiming (NEW)
│   └── Analytics.sol              # Analytics & Metrics (NEW)
├── scripts/
│   └── deploy.ts                  # Hardhat deployment script
├── tests/
│   ├── AirdropManager.test.ts
│   ├── AirdropToken.test.ts
│   ├── VestingSchedule.test.ts
│   └── ETHAirdropManager.test.ts
├── hardhat.config.ts              # Hardhat configuration
├── package.json                   # Dependencies
└── .env.example                   # Environment template
```

## Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation

```bash
# Clone repository
git clone <repo-url>
cd AirStack

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
```

### Configuration

Edit `.env` with your settings:

```env
# Base RPC endpoints
BASE_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

# Deployment account
PRIVATE_KEY=your_private_key_here

# Block explorer
BASESCAN_API_KEY=your_basescan_api_key_here
```

### Compile Contracts

```bash
npm run compile
```

### Run Tests

```bash
npm test
```

### Deploy to Base Testnet

```bash
npm run deploy:base-testnet
```

### Deploy to Base Mainnet

```bash
npm run deploy:base-mainnet
```

## Smart Contract Functions

### AirdropToken
- `transfer(to, amount)` - Transfer tokens
- `mint(to, amount)` - Mint new tokens (owner only)
- `burn(amount)` - Burn tokens
- `balanceOf(account)` - Get balance
- `totalSupply()` - Get total supply

### AirdropManager
- `createAirdrop(token, totalAmount, startTime, endTime)` - Create new airdrop
- `setAllocation(airdropId, recipient, amount)` - Set user allocation
- `batchSetAllocations(airdropId, recipients[], amounts[])` - Batch allocations
- `claimTokens(airdropId)` - Claim airdrop tokens
- `isAirdropActive(airdropId)` - Check if airdrop is active
- `getAllocation(airdropId, recipient)` - Get user allocation
- `pause()` / `unpause()` - Pause/resume claiming

### ETHAirdropManager (NEW)
- `createETHAirdrop(startTime, endTime)` - Create ETH airdrop with deposit
- `setETHAllocation(airdropId, recipient, amount)` - Set ETH allocation
- `batchSetETHAllocations(airdropId, recipients[], amounts[])` - Batch ETH allocations
- `claimETH(airdropId)` - Claim native ETH
- `depositETH(airdropId)` - Add more ETH to airdrop

### WhitelistManager
- `addToWhitelist(user, tier)` - Add user to whitelist
- `batchAddToWhitelist(users[], tier)` - Batch add users
- `removeFromWhitelist(user)` - Remove user
- `isWhitelisted(user)` - Check whitelist status
- `setTierMetadata(tier, name, maxAllocation)` - Configure tiers
- `updateUserTier(user, newTier)` - Update user tier

### VestingSchedule
- `createVestingSchedule(token, beneficiary, amount, start, cliff, end)` - Create vesting
- `claimVestedTokens(scheduleId)` - Claim vested tokens
- `calculateVested(scheduleId)` - Calculate vested amount
- `getClaimableAmount(scheduleId)` - Get immediately claimable amount

### Governance
- `createProposal(title, description, duration)` - Create proposal
- `vote(proposalId, position)` - Vote on proposal
- `allocateGovernanceTokens(holder, amount)` - Give voting power
- `executeProposal(proposalId)` - Close voting
- `getProposalStatus(proposalId)` - Get proposal result

### MerkleTree
- `createMerkleAirdrop(root, token, totalAmount, startTime, endTime)` - Create merkle airdrop
- `claimMerkleTokens(airdropId, amount, proof[])` - Claim with merkle proof
- `verifyMerkleProof(airdropId, claimant, amount, proof[])` - Verify proof validity
- `updateMerkleRoot(airdropId, newRoot)` - Update merkle root

### AirdropAggregator (NEW)
- `registerAirdrop(airdropId, airdropContract)` - Register airdrop for aggregation
- `aggregatedClaim(airdropIds[])` - Claim from multiple airdrops at once
- `getAirdropReference(airdropId)` - Get registered airdrop info

### Analytics (NEW)
- `recordClaim(airdropId, participant, amount)` - Record a claim event
- `getAirdropMetrics(airdropId)` - Get airdrop statistics
- `getDailyStats(airdropId, day)` - Get daily statistics
- `getClaimRate(airdropId, totalEligible)` - Calculate claim percentage
- `getTotalClaimedAmount(airdropId)` - Get total claimed
- `getTotalClaimers(airdropId)` - Get claimers count

## Gas Optimization

Base Chain benefits:
- **Lower Gas Costs**: 4-40x cheaper than Ethereum mainnet
- **Faster Finality**: ~2 second block time
- **EIP-1559 Compatible**: Predictable gas pricing
- **Optimized Contracts**: Batch operations reduce per-claim costs

## Security Features

✅ OpenZeppelin standard library usage
✅ ReentrancyGuard on sensitive functions
✅ Pausable emergency controls
✅ Owner-only administrative functions
✅ Input validation on all external functions
✅ Event logging for transparency

## Testing

```bash
# Run all tests
npm test

# Run specific test
npx hardhat test tests/AirdropManager.test.ts

# Run with gas report
REPORT_GAS=true npm test
```

## Deployment

The deployment script (`scripts/deploy.ts`) deploys all contracts and:
1. Deploys AirdropToken
2. Deploys AirdropManager
3. Deploys WhitelistManager
4. Deploys VestingSchedule
5. Deploys Governance
6. Deploys MerkleTree
7. Deploys ETHAirdropManager
8. Deploys AirdropAggregator
9. Deploys Analytics
10. Transfers initial tokens to AirdropManager

## Configuration Examples

### Token Airdrop
```typescript
const airdrop = await manager.createAirdrop(
  tokenAddress,
  ethers.parseUnits("1000000", 6),  // 1M tokens
  startTime,
  endTime
);

await manager.batchSetAllocations(airdropId, recipients, amounts);
```

### ETH Airdrop
```typescript
const ethAirdrop = await ethManager.createETHAirdrop(
  startTime,
  endTime,
  { value: ethers.parseEther("100") }  // 100 ETH
);

await ethManager.batchSetETHAllocations(airdropId, recipients, amounts);
```

### Vesting Schedule
```typescript
const vesting = await vestingSchedule.createVestingSchedule(
  tokenAddress,
  beneficiary,
  ethers.parseUnits("10000", 6),
  startTime,
  cliffTime,    // 1 year later
  endTime       // 4 years later
);
```

### Multi-Campaign Claiming
```typescript
// User claims from 3 airdrops in one transaction
await aggregator.aggregatedClaim([airdropId1, airdropId2, airdropId3]);
```

## Base Testnet Faucet

Get testnet ETH for Base Sepolia:
- https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

## Links

- **Base Documentation**: https://docs.base.org
- **Hardhat Documentation**: https://hardhat.org
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Solidity Documentation**: https://docs.soliditylang.org

## License

MIT

## Support

For issues and questions:
1. Check the [FAQ](./FAQ.md)
2. Review existing [issues](https://github.com/web3joker/airstack/issues)
3. Open a new issue with details and steps to reproduce
├── scripts/
│   ├── deploy.ts                    # Deployment Script
│   ├── airdrop-setup.ts            # Setup Configuration
│   ├── merkle-utils.ts             # Merkle Tree Utilities
│   └── airstack-cli.ts             # CLI Interface
├── Clarinet.toml
├── package.json
├── DEPLOYMENT.md
└── README.md
``` ├── deploy.ts
│   └── airdrop-setup.ts
├── Clarinet.toml
└── README.md
```

## Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity smart contract development tool
- Node.js >= 16.x
- Stacks wallet for deployment

## Installation

```bash
# Install Clarinet
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
sudo mv clarinet /usr/local/bin/

# Initialize the project
clarinet integrate

# Run tests
clarinet test
```

## Usage

Deploy Contracts

```bash
clarinet deployments generate --mainnet
clarinet deployments apply -p deployments/default.mainnet-plan.yaml
```

Create Airdrop Campaign

1. Deploy the token contract
2. Deploy the whitelist manager
3. Deploy the airdrop manager
4. Add addresses to whitelist
5. Fund the airdrop manager contract
6. Users can claim tokens

Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/airdrop-manager.test.ts
```

## Advanced Features

### Aggregated Multi-Airdrop Claims (Single TX)

Allows users to claim tokens from multiple airdrop campaigns in a single transaction:
- **Combine multiple claim types**: Whitelist + Merkle + Vesting in one call
- **Proof verification**: Automatic verification for merkle-based claims
- **Double-claim prevention**: Built-in tracking prevents claiming the same campaign twice
- **Gas optimization**: Save on transaction fees by batching up to 10 claims
- **Claim tracking**: Full history of aggregated claims per user

**Example Use Case**: A user eligible for 3 whitelist airdrops, 2 merkle-verified campaigns, and 1 vesting schedule can claim all in a single transaction instead of 6 separate transactions.

### Vesting Schedules
- Create time-locked token releases with configurable cliff periods
- Linear vesting after cliff with automatic calculations
- Track vesting progress and claimable amounts
- Support for multiple simultaneous vesting schedules

### Governance & DAO
- Community voting on airdrop proposals
- Token-weighted voting system
- Proposal creation and management
- Vote tracking and execution

### Merkle Trees
- Generate merkle proofs for batch claims
- Verify claims without storing entire whitelist on-chain
- Efficient gas usage for large airdrops
- Prevent double-spending automatically

### Analytics & Tracking
- Track total distributions and claims
- Per-user claim history
- Campaign statistics and metrics
- Governance participation tracking

## Contract Functions

Airdrop Manager
- `(create-airdrop (token-amount uint) (start-block uint) (end-block uint))`: Create new airdrop
- `(claim-tokens (airdrop-id uint))`: Claim tokens from airdrop
- `(set-allocation (airdrop-id uint) (recipient principal) (amount uint))`: Set user allocation
- `(batch-set-allocations (airdrop-id uint) (recipients (list 200 principal)) (amounts (list 200 uint)))`: Batch allocations
- `(pause-contract)`: Emergency pause
- `(unpause-contract)`: Resume operations

Whitelist Manager
- `(add-to-whitelist (address principal) (tier uint))`: Add with tier
- `(batch-add-to-whitelist (addresses (list 200 principal)) (tier uint))`: Batch add
- `(remove-from-whitelist (address principal))`: Remove address
- `(is-whitelisted (address principal))`: Check status
- `(set-tier-metadata (tier uint) (name (string-ascii 50)) (max-allocation uint))`: Configure tiers

Vesting Schedule
- `(create-vesting-schedule (beneficiary principal) (total-amount uint) (start-block uint) (cliff-block uint) (end-block uint))`: Create schedule
- `(claim-vested-tokens (schedule-id uint))`: Claim available tokens
- `(get-claimable-amount (schedule-id uint) (beneficiary principal))`: Check claimable amount
- `(get-vesting-schedule (schedule-id uint))`: Get schedule details

Governance
- `(create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (duration uint))`: Create proposal
- `(vote-on-proposal (proposal-id uint) (position bool))`: Vote yes/no
- `(execute-proposal (proposal-id uint))`: Execute passed proposal
- `(mint-governance-tokens (amount uint) (recipient principal))`: Mint voting tokens

Merkle Tree
- `(register-merkle-root (root (buff 32)))`: Register new merkle root
- `(verify-proof (root-id uint) (leaf (buff 32)) (proof (list 32 (buff 32))))`: Verify inclusion proof
- `(mark-leaf-claimed (root-id uint) (leaf-hash (buff 32)))`: Mark as claimed

Multi-Claim Aggregator
- `(aggregate-multi-claim (whitelist-airdrops (list 10 uint)) (merkle-claims (list 10 {...})) (vesting-schedules (list 10 uint)))`: Claim from multiple campaigns in one transaction
- `(claim-from-whitelist-airdrop (airdrop-id uint))`: Claim from single whitelist airdrop
- `(claim-from-merkle-airdrop (root-id uint) (leaf (buff 32)) (proof (list 32 (buff 32))))`: Claim from merkle-verified campaign
- `(claim-from-vesting (schedule-id uint))`: Claim vested tokens
- `(has-claimed-campaign (user principal) (campaign-type (string-ascii 20)) (campaign-id uint))`: Check if user claimed from campaign
- `(activate-aggregator)`: Enable aggregated claims
- `(deactivate-aggregator)`: Disable aggregated claims

Token Contract
Standard SIP-010 functions:
- `(transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))`
- `(get-balance (who principal))`
- `(get-total-supply)`
- `(mint (amount uint) (recipient principal))`
- `(burn (amount uint))`

## Security Features

- Owner-only administrative functions with validation
- Whitelist verification for all claims
- Block height restrictions and time-locks
- Pause/unpause mechanism for emergency stops
- Double-spend prevention with claim tracking
- Merkle proof verification for integrity
- Governance access control with token weighting
- No reentrancy vulnerabilities
- Comprehensive error codes for debugging

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Contact

For questions or support, please open an issue on GitHub.
