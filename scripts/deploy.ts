import { ethers } from "hardhat";

async function main() {
  console.log("Deploying AirStack Airdrop System to Base Chain...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Deploy AirdropToken
  console.log("\nDeploying AirdropToken...");
  const AirdropToken = await ethers.getContractFactory("AirdropToken");
  const token = await AirdropToken.deploy();
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("AirdropToken deployed to:", tokenAddress);

  // Deploy AirdropManager
  console.log("\nDeploying AirdropManager...");
  const AirdropManager = await ethers.getContractFactory("AirdropManager");
  const manager = await AirdropManager.deploy();
  await manager.waitForDeployment();
  const managerAddress = await manager.getAddress();
  console.log("AirdropManager deployed to:", managerAddress);

  // Deploy WhitelistManager
  console.log("\nDeploying WhitelistManager...");
  const WhitelistManager = await ethers.getContractFactory("WhitelistManager");
  const whitelist = await WhitelistManager.deploy();
  await whitelist.waitForDeployment();
  const whitelistAddress = await whitelist.getAddress();
  console.log("WhitelistManager deployed to:", whitelistAddress);

  // Deploy VestingSchedule
  console.log("\nDeploying VestingSchedule...");
  const VestingSchedule = await ethers.getContractFactory("VestingSchedule");
  const vesting = await VestingSchedule.deploy();
  await vesting.waitForDeployment();
  const vestingAddress = await vesting.getAddress();
  console.log("VestingSchedule deployed to:", vestingAddress);

  // Deploy Governance
  console.log("\nDeploying Governance...");
  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy();
  await governance.waitForDeployment();
  const governanceAddress = await governance.getAddress();
  console.log("Governance deployed to:", governanceAddress);

  // Deploy MerkleTree
  console.log("\nDeploying MerkleTree...");
  const MerkleTree = await ethers.getContractFactory("MerkleTree");
  const merkleTree = await MerkleTree.deploy();
  await merkleTree.waitForDeployment();
  const merkleAddress = await merkleTree.getAddress();
  console.log("MerkleTree deployed to:", merkleAddress);

  // Deploy ETHAirdropManager
  console.log("\nDeploying ETHAirdropManager...");
  const ETHAirdropManager = await ethers.getContractFactory("ETHAirdropManager");
  const ethManager = await ETHAirdropManager.deploy();
  await ethManager.waitForDeployment();
  const ethManagerAddress = await ethManager.getAddress();
  console.log("ETHAirdropManager deployed to:", ethManagerAddress);

  // Deploy AirdropAggregator
  console.log("\nDeploying AirdropAggregator...");
  const AirdropAggregator = await ethers.getContractFactory("AirdropAggregator");
  const aggregator = await AirdropAggregator.deploy();
  await aggregator.waitForDeployment();
  const aggregatorAddress = await aggregator.getAddress();
  console.log("AirdropAggregator deployed to:", aggregatorAddress);

  // Deploy Analytics
  console.log("\nDeploying Analytics...");
  const Analytics = await ethers.getContractFactory("Analytics");
  const analytics = await Analytics.deploy();
  await analytics.waitForDeployment();
  const analyticsAddress = await analytics.getAddress();
  console.log("Analytics deployed to:", analyticsAddress);

  // Save deployment addresses
  const deploymentInfo = {
    network: "base",
    timestamp: new Date().toISOString(),
    deployer: deployer.address,
    contracts: {
      AirdropToken: tokenAddress,
      AirdropManager: managerAddress,
      WhitelistManager: whitelistAddress,
      VestingSchedule: vestingAddress,
      Governance: governanceAddress,
      MerkleTree: merkleAddress,
      ETHAirdropManager: ethManagerAddress,
      AirdropAggregator: aggregatorAddress,
      Analytics: analyticsAddress,
    },
  };

  console.log("\n=== DEPLOYMENT SUMMARY ===");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  // Transfer some tokens to manager for testing
  console.log("\nTransferring tokens to AirdropManager...");
  const transferAmount = ethers.parseUnits("1000000", 6); // 1M tokens
  await token.transfer(managerAddress, transferAmount);
  console.log("Transferred 1,000,000 tokens to AirdropManager");

  console.log("\nDeployment complete!");
  return deploymentInfo;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
