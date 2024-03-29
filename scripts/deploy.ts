// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
  BadgePriceOracle,
  BadgeRegistry,
  BadgeTokenFactory,
  BadgeXP,
  EntityFactory,
  PermissionTokenFactory,
  BadgeRecoveryOracle,
  BadgeXPOracle,
} from "../typechain";

// ** CONFIGS ** \\
const numberOfSecondsToWaitBetweenTransactions: number = 10;

// ** HELPER FUNCTIONS ** \\
async function wait(seconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}

async function waitForSetAmountOfTime(): Promise<void> {
  return wait(numberOfSecondsToWaitBetweenTransactions);
}

const mainnetTreasury = "0x63373c25277607fe5c14d5d18D70AfCD418C43e2";
const rinkebyTreasury = "0xd1450649e41241AAdE6710817210C7703C8Eba4E";

const securedBadgeWallet = ""0x95dE2aF29E3cc1B776C70ECe4c6392022B1180dC""

// ** DEPLOY SCRIPT ** \\
async function main() {
  // 1. Deploy badge registry
  let badgeRegistry: BadgeRegistry;
  const badgeRegistryContract = await ethers.getContractFactory(
    "BadgeRegistry"
  );
  let badgeRegistryAddress: string;
  // badgeRegistry = badgeRegistryContract.attach(badgeRegistryAddress);

  try {
    console.log("Attempting to deploy Badge registry...");
    badgeRegistry = await badgeRegistryContract.deploy();
    await badgeRegistry.deployed();
    badgeRegistryAddress = badgeRegistry.address;
    console.log(
      "Successfully deployed Badge Registry to address: ",
      badgeRegistryAddress
    );
  } catch (e) {
    throw new Error(`Failed to deploy Badge registry due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // 2. Deploy badge recovery oracle
  let recoveryOracle: BadgeRecoveryOracle;
  try {
    const badgeRecoveryOracleContract = await ethers.getContractFactory(
      "BadgeRecoveryOracle"
    );
    console.log("Attempting to deploy Badge recovery oracle...");
    recoveryOracle = await badgeRecoveryOracleContract.deploy();
    await recoveryOracle.deployed();
    console.log(
      "Successfully deployed BadgeRecoveryOracle to address: ",
      recoveryOracle.address
    );
  } catch (e) {
    throw new Error(`Failed to deploy BadgePriceCalculator due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // NOTE: REMOVE THIS OUT ON ACTUAL DEPLOY
  const recoveryOracleAddress = recoveryOracle.address;

  // 2.1. Set Badge recovery oracle
  try {
    console.log("Attempting to set BadgeRecoveryOracle in badge registry...");
    await badgeRegistry.setRecoveryOracle(recoveryOracleAddress);
    console.log("Successfully set BadgePriceCalculator in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set BadgePriceOracle in badge registry due to error: ${e}`
    );
  }

  await waitForSetAmountOfTime();

  // 3. Deploy and set entity factory
  let entityFactory: EntityFactory;
  try {
    const entityFactoryContract = await ethers.getContractFactory(
      "EntityFactory"
    );
    console.log("Attempting to deploy entity factory...");
    entityFactory = await entityFactoryContract.deploy(badgeRegistryAddress);
    await entityFactory.deployed();
    console.log(
      "Successfully deployed entity factory deployed to address: ",
      entityFactory.address
    );
  } catch (e) {
    throw new Error(`Failed to deploy entity factory due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // 3.1 Set entity factory in Badge registry
  try {
    console.log("Attempting to set entity factory in badge registry...");
    await badgeRegistry.setEntityFactory(entityFactory.address);
    console.log("Successfully set entity factory in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set entity factory in badge registry due to error: ${e}`
    );
  }

  await waitForSetAmountOfTime();

  // 4. Deploy and set badge factory
  let badgeTokenFactory: BadgeTokenFactory;
  try {
    const badgeTokenFactoryContract = await ethers.getContractFactory(
      "BadgeTokenFactory"
    );
    console.log("Attempting to deploy badge factory...");
    badgeTokenFactory = await badgeTokenFactoryContract.deploy();
    await badgeTokenFactory.deployed();
    console.log(
      "Successfully deployed badge factory deployed to address: ",
      badgeTokenFactory.address
    );
  } catch (e) {
    throw new Error(`Failed to deploy badge factory due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // 4.1 Set badge factory in Badge registry
  try {
    console.log("Attempting to set badge factory in badge registry...");
    await badgeRegistry.setBadgeTokenFactory(badgeTokenFactory.address);
    console.log("Successfully set badge factory in badge registry.");
  } catch (e) {
    throw new Error(
      "Failed to set badge factory in badge registry due to error: " + e
    );
  }

  await waitForSetAmountOfTime();

  // 5. Deploy and set permission token factory
  let permissionTokenFactory: PermissionTokenFactory;
  try {
    const permissionTokenFactoryContract = await ethers.getContractFactory(
      "PermissionTokenFactory"
    );
    console.log("Attempting to deploy permission token factory...");
    permissionTokenFactory = await permissionTokenFactoryContract.deploy();
    await permissionTokenFactory.deployed();
    console.log(
      "Successfully deployed permission token factory to address: ",
      permissionTokenFactory.address
    );
  } catch (e) {
    throw new Error(
      `Failed to deploy permission token factory due to error: ${e}`
    );
  }

  await waitForSetAmountOfTime();

  // 5.1 Set permission token factory in Badge registry
  try {
    console.log(
      "Attempting to set permission token factory in badge registry..."
    );
    await badgeRegistry.setPermissionTokenFactory(
      permissionTokenFactory.address
    );
    console.log("Successfully set permission token factory in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set permission token factory in badge registry due to error: ${e}`
    );
  }

  await waitForSetAmountOfTime();

  // 6. Deploy and set BadgeXP token
  let badgeXPToken: BadgeXP;
  try {
    const badgeXPTokenContract = await ethers.getContractFactory("BadgeXP");
    console.log("Attempting to deploy BadgeXP token...");
    badgeXPToken = await badgeXPTokenContract.deploy(
      badgeRegistryAddress,
      recoveryOracleAddress
    );
    await badgeXPToken.deployed();
    console.log(
      "Successfully deployed BadgeXP token to address: ",
      badgeXPToken.address
    );
  } catch (e) {
    throw new Error(`Failed to deploy BadgeXP token due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // 6.1 Set BadgeXP Token
  try {
    console.log("Attempting to set BadgeXP token in badge registry...");
    await badgeRegistry.setBadgeXPToken(badgeXPToken.address);
    console.log("Successfully set BadgeXP token in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set BadgeXP token in badge registry due to error: ${e}`
    );
  }

  await waitForSetAmountOfTime();

  // 7. Deploy BadgeXPOracle
  let badgeXPOracle: BadgeXPOracle;
  try {
    const badgeXPOracleTokenContract = await ethers.getContractFactory(
      "BadgeXPOracle"
    );
    console.log("Attempting to deploy BadgeXPOracle...");
    badgeXPOracle = await badgeXPOracleTokenContract.deploy();
    await badgeXPOracle.deployed();
    console.log(
      "Successfully deployed BadgeXPOracle to address: ",
      badgeXPOracle.address
    );
  } catch (e) {
    throw new Error(`Failed to deploy BadgeXPOracle  due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // 7.1 Set badgeXPOracle
  try {
    console.log("Attempting to set BadgeXPOracle in badgeXP...");
    await badgeXPToken.setXPOracle(badgeXPOracle.address);
    console.log("Successfully set BadgeXPOracle in badgeXP.");
  } catch (e) {
    throw new Error(
      `Failed to set BadgeXPOracle in badgeXP due to error: ${e}`
    );
  }

  await waitForSetAmountOfTime();

  // 8. Deploy Badge Price Oracle
  let badgePriceOracle: BadgePriceOracle;
  try {
    const badgePriceOracleContract = await ethers.getContractFactory(
      "BadgePriceOracle"
    );
    console.log("Attempting to deploy BadgePriceOracle...");
    badgePriceOracle = await badgePriceOracleContract.deploy(
      badgeRegistryAddress
    );
    await badgePriceOracle.deployed();
    console.log(
      "Successfully deployed BadgePriceOracle to address: ",
      badgePriceOracle.address
    );
  } catch (e) {
    throw new Error(`Failed to deploy BadgePriceOracle due to error: ${e}`);
  }

  await waitForSetAmountOfTime();

  // 8.1 Set BadgePrice oracle
  try {
    console.log("Attempting to set BadgePriceOracle in badge registry...");
    await badgeRegistry.setBadgePriceOracle(badgePriceOracle.address);
    console.log("Successfully set BadgePriceOracle in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set BadgePriceOracle in badge registry due to error: ${e}`
    );
  }

  // 9. Set badge treasury
  try {
    console.log("Attempting to set Badge treasury");
    await badgeRegistry.setBadgeTreasury(mainnetTreasury);
    console.log("Successfully set Badge treasury");
  } catch (e) {
    throw new Error(`Failed to set Badge treasury due to error: ${e}`);
  }

  // 10. Request new deployer
  try {
    console.log("Attempting to set request new deployer");
    await badgeRegistry.requestNewDeployer(
      securedBadgeWallet
    );
    console.log("Successfully requested new deployer");
  } catch (e) {
    throw new Error(`Failed to request new deployer due to error: ${e}`);
  }

  console.log("Successfully deployed Badge contracts!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
