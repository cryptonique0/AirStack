# Deployment Guide

## Prerequisites

1. Install Clarinet:
```bash
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
sudo mv clarinet /usr/local/bin/
```

2. Install Node.js dependencies:
```bash
npm install
```

3. Set up your Stacks wallet and get your private key

## Local Testing

Run tests locally with Clarinet:

```bash
clarinet test
```

Check contract syntax:

```bash
clarinet check
```

Open Clarinet console for interactive testing:

```bash
clarinet console
```

## Deployment to Testnet

1. Set environment variables:
```bash
export STACKS_PRIVATE_KEY="your_private_key_here"
export NETWORK="testnet"
```

2. Generate deployment plan:
```bash
clarinet deployments generate --testnet
```

3. Deploy contracts:
```bash
npm run deploy:testnet
```

Or manually:
```bash
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

## Deployment to Mainnet

⚠️ **Warning**: Deploying to mainnet requires real STX tokens and is irreversible.

1. Set environment variables:
```bash
export STACKS_PRIVATE_KEY="your_private_key_here"
export NETWORK="mainnet"
```

2. Generate deployment plan:
```bash
clarinet deployments generate --mainnet
```

3. Review the deployment plan carefully

4. Deploy contracts:
```bash
npm run deploy:mainnet
```

## Post-Deployment Setup

After deploying, you need to set up the airdrop:

1. Set your contract address:
```bash
export CONTRACT_ADDRESS="your_deployed_contract_address"
```

2. Edit `scripts/airdrop-setup.ts` to add recipient addresses and amounts

3. Run the setup script:
```bash
npx ts-node scripts/airdrop-setup.ts
```

## Airdrop Campaign Steps

### 1. Create Airdrop Campaign

```clarity
(contract-call? .airdrop-manager create-airdrop 
  .airdrop-token 
  u1000000000000  ;; Total amount
  u1              ;; Start block
  u100000         ;; End block
)
```

### 2. Add Addresses to Whitelist

Single address:
```clarity
(contract-call? .whitelist-manager add-to-whitelist 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  u1  ;; Tier
)
```

Batch add:
```clarity
(contract-call? .whitelist-manager batch-add-to-whitelist 
  (list 'ST1... 'ST2... 'ST3...)
  u1  ;; Tier
)
```

### 3. Set Token Allocations

Single allocation:
```clarity
(contract-call? .airdrop-manager set-allocation 
  u1                                          ;; Airdrop ID
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; Recipient
  u5000000                                    ;; Amount
)
```

Batch allocations:
```clarity
(contract-call? .airdrop-manager batch-set-allocations 
  u1                           ;; Airdrop ID
  (list 'ST1... 'ST2... 'ST3...)  ;; Recipients
  (list u5000000 u10000000 u15000000)  ;; Amounts
)
```

### 4. Users Claim Tokens

Users can claim their allocated tokens:
```clarity
(contract-call? .airdrop-manager claim-tokens u1)  ;; Airdrop ID
```

## Admin Functions

### Pause/Unpause Contract

```clarity
;; Pause (emergency stop)
(contract-call? .airdrop-manager pause-contract)

;; Unpause
(contract-call? .airdrop-manager unpause-contract)
```

### Activate/Deactivate Airdrop

```clarity
;; Deactivate specific airdrop
(contract-call? .airdrop-manager deactivate-airdrop u1)

;; Reactivate
(contract-call? .airdrop-manager activate-airdrop u1)
```

### Manage Whitelist

```clarity
;; Remove from whitelist
(contract-call? .whitelist-manager remove-from-whitelist 'ST1...)

;; Deactivate entire whitelist
(contract-call? .whitelist-manager deactivate-whitelist)
```

## Monitoring

### Check Airdrop Status

```clarity
(contract-call? .airdrop-manager get-airdrop u1)
(contract-call? .airdrop-manager is-airdrop-active u1)
```

### Check User Claims

```clarity
(contract-call? .airdrop-manager has-claimed u1 'ST1...)
(contract-call? .airdrop-manager get-allocation u1 'ST1...)
```

### Check Whitelist Status

```clarity
(contract-call? .whitelist-manager is-whitelisted 'ST1...)
(contract-call? .whitelist-manager get-whitelist-info 'ST1...)
(contract-call? .whitelist-manager get-total-whitelisted)
```

## Troubleshooting

### Contract Deployment Fails

- Ensure you have enough STX for transaction fees
- Check that contract names are unique
- Verify Clarity syntax with `clarinet check`

### Claim Transactions Fail

- Verify user is whitelisted
- Check if allocation is set
- Ensure airdrop is active and within block range
- Confirm contract is not paused

### Whitelist Issues

- Only contract owner can manage whitelist
- Check if whitelist is active
- Verify tier assignments are correct

## Security Best Practices

1. **Test Thoroughly**: Always test on testnet before mainnet
2. **Audit Contracts**: Have contracts audited by professionals
3. **Monitor Activity**: Set up alerts for unusual activity
4. **Emergency Controls**: Know how to pause contracts if needed
5. **Key Management**: Securely store private keys
6. **Access Control**: Verify owner-only functions are protected

## Support

For issues or questions:
- Review contract code in `/contracts` directory
- Check test files in `/tests` for usage examples
- Open an issue on GitHub
