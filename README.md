# AirStack - Token Airdrop System on Stacks Blockchain

A comprehensive token airdrop system built with Clarity smart contracts for the Stacks blockchain.

## Features

- SIP-010 Compliant Token: Fungible token standard implementation
- Whitelist Management: Secure whitelist system for eligible addresses with tiered support
- Batch Airdrop: Efficiently distribute tokens to multiple addresses
- Merkle Tree Verification: Gas-efficient proof-based claim system
- **Aggregated Multi-Airdrop Claims**: Claim from multiple campaigns in a single transaction
- Admin Controls: Owner-only functions for managing airdrops
- Emergency Controls: Pause/unpause functionality for security
- Vesting Schedules: Time-locked distributions with cliff and linear vesting
- Governance & DAO: Community voting on airdrop parameters
- Analytics & Tracking: Comprehensive metrics and claim statistics
- Multi-Campaign Support: Run multiple simultaneous airdrops

## Architecture

Smart Contracts

1. airdrop-token.clar: SIP-010 fungible token contract
2. airdrop-manager.clar: Main airdrop distribution logic
3. whitelist-manager.clar: Whitelist management system with tiered allocations
4. vesting-schedule.clar: Time-locked token distribution with cliff periods
5. multi-claim-aggregator.clar: Aggregate claims from multiple campaigns in one transaction
6. governance.clar: DAO voting and proposal system
7. merkle-tree.clar: Merkle proof verification for efficient claims
8. analytics.clar: Comprehensive tracking and statistics
## Project Structure

```
AirStack/
├── contracts/
│   ├── airdrop-token.clar           # SIP-010 Token
│   ├── airdrop-manager.clar         # Airdrop Management
│   ├── whitelist-manager.clar       # Whitelist with Tiers
│   ├── vesting-schedule.clar        # Vesting Logic
│   ├── governance.clar              # DAO Voting
│   ├── merkle-tree.clar             # Merkle Proofs
│   ├── multi-claim-aggregator.clar  # Multi-Campaign Claims
│   └── analytics.clar               # Analytics & Stats
├── tests/
│   ├── airdrop-token_test.ts
│   ├── airdrop-manager_test.ts
│   ├── whitelist-manager_test.ts
│   ├── vesting-schedule_test.ts
│   ├── governance_test.ts
│   └── multi-claim-aggregator_test.ts
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
