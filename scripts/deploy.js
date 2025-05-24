const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying YieldFarm contract with account:", deployer.address);

  const YieldFarm = await hre.ethers.getContractFactory("YieldFarm");

  // Pass stakingToken, rewardToken addresses and rewardRate (example: 1 token per block)
  const stakingTokenAddress = "0xYourStakingTokenAddress";
  const rewardTokenAddress = "0xYourRewardTokenAddress";
  const rewardRate = hre.ethers.utils.parseUnits("1", 18); // 1 token/block

  const yieldFarm = await YieldFarm.deploy(stakingTokenAddress, rewardTokenAddress, rewardRate);

  await yieldFarm.deployed();

  console.log("YieldFarm deployed to:", yieldFarm.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
