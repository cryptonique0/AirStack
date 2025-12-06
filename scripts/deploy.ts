import { makeContractDeploy, broadcastTransaction, AnchorMode } from '@stacks/transactions';
import { StacksTestnet, StacksMainnet } from '@stacks/network';
import * as fs from 'fs';

interface DeployConfig {
  network: 'testnet' | 'mainnet';
  senderKey: string;
  contractName: string;
  codeBody: string;
}

async function deployContract(config: DeployConfig) {
  const network = config.network === 'mainnet' 
    ? new StacksMainnet() 
    : new StacksTestnet();

  console.log(`Deploying ${config.contractName} to ${config.network}...`);

  const txOptions = {
    contractName: config.contractName,
    codeBody: config.codeBody,
    senderKey: config.senderKey,
    network,
    anchorMode: AnchorMode.Any,
  };

  try {
    const transaction = await makeContractDeploy(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    
    console.log(`Transaction ID: ${broadcastResponse.txid}`);
    console.log(`Contract deployed successfully!`);
    
    return broadcastResponse;
  } catch (error) {
    console.error(`Error deploying contract:`, error);
    throw error;
  }
}

async function deployAll() {
  // Read environment variables
  const network = (process.env.NETWORK || 'testnet') as 'testnet' | 'mainnet';
  const senderKey = process.env.STACKS_PRIVATE_KEY;

  if (!senderKey) {
    throw new Error('STACKS_PRIVATE_KEY environment variable is required');
  }

  // Read contract files
  const tokenCode = fs.readFileSync('./contracts/airdrop-token.clar', 'utf8');
  const whitelistCode = fs.readFileSync('./contracts/whitelist-manager.clar', 'utf8');
  const airdropCode = fs.readFileSync('./contracts/airdrop-manager.clar', 'utf8');

  console.log('Starting deployment sequence...\n');

  // Deploy contracts in order
  try {
    // 1. Deploy token contract
    await deployContract({
      network,
      senderKey,
      contractName: 'airdrop-token',
      codeBody: tokenCode,
    });

    console.log('\nWaiting 30 seconds before next deployment...\n');
    await new Promise(resolve => setTimeout(resolve, 30000));

    // 2. Deploy whitelist manager
    await deployContract({
      network,
      senderKey,
      contractName: 'whitelist-manager',
      codeBody: whitelistCode,
    });

    console.log('\nWaiting 30 seconds before next deployment...\n');
    await new Promise(resolve => setTimeout(resolve, 30000));

    // 3. Deploy airdrop manager
    await deployContract({
      network,
      senderKey,
      contractName: 'airdrop-manager',
      codeBody: airdropCode,
    });

    console.log('\n✅ All contracts deployed successfully!');
  } catch (error) {
    console.error('\n❌ Deployment failed:', error);
    process.exit(1);
  }
}

// Run deployment
deployAll();
