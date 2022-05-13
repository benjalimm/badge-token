// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
  BadgeRegistry,
  BadgeTokenFactory,
  BadgeXP,
  EntityFactory,
  PermissionTokenFactory,
} from "../typechain";

async function wait(seconds: number) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}

async function main() {
  // 1. Deploy badge registry
  let badgeRegistry: BadgeRegistry;
  let badgeRegistryAddress: string;

  try {
    console.log("Attempting to deploy Badge registry...");
    const badgeRegistryContract = await ethers.getContractFactory(
      "BadgeRegistry"
    );
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

  await wait(10);

  // 2. Deploy and set entity factory
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

  await wait(10);

  // 2.1 Set entity factory in Badge registry
  try {
    console.log("Attempting to set entity factory in badge registry...");
    await badgeRegistry.setEntityFactory(entityFactory.address);
    console.log("Successfully set entity factory in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set entity factory in badge registry due to error: ${e}`
    );
  }

  await wait(10);

  // 3. Deploy and set badge factory
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

  await wait(10);

  // 3.1 Set badge factory in Badge registry
  try {
    console.log("Attempting to set badge factory in badge registry...");
    await badgeRegistry.setBadgeTokenFactory(badgeTokenFactory.address);
    console.log("Successfully set badge factory in badge registry.");
  } catch (e) {
    throw new Error(
      "Failed to set badge factory in badge registry due to error: " + e
    );
  }

  await wait(10);

  // 4. Deploy and set permission token factory
  let permissionTokenFactory: PermissionTokenFactory;
  try {
    const permissionTokenFactoryContract = await ethers.getContractFactory(
      "PermissionTokenFactory"
    );
    console.log("Attempting to deploy permission token factory...");
    permissionTokenFactory = await permissionTokenFactoryContract.deploy();
    await permissionTokenFactory.deployed();
    console.log("Successfully deployed permission token factory.");
  } catch (e) {
    throw new Error(
      `Failed to deploy permission token factory due to error: ${e}`
    );
  }

  await wait(10);

  // 4.1 Set permission token factory in Badge registry
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

  await wait(10);

  // 5. Deploy and set BadgeXP token
  let badgeXPToken: BadgeXP;
  try {
    const badgeXPTokenContract = await ethers.getContractFactory("BadgeXP");
    console.log("Attempting to deploy BadgeXP token...");
    badgeXPToken = await badgeXPTokenContract.deploy(badgeRegistryAddress);
    await badgeXPToken.deployed();
    console.log("Successfully deployed BadgeXP token.");
  } catch (e) {
    throw new Error(`Failed to deploy BadgeXP token due to error: ${e}`);
  }

  await wait(10);

  // 5.1 Set BadgeXP Token
  try {
    console.log("Attempting to set BadgeXP token in badge registry...");
    await badgeRegistry.setBadgeXPToken(badgeXPToken.address);
    console.log("Successfully set BadgeXP token in badge registry.");
  } catch (e) {
    throw new Error(
      `Failed to set BadgeXP token in badge registry due to error: ${e}`
    );
  }

  console.log("Successfully deployed Badge contracts!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
