import { ethers } from "hardhat";
import { BadgeRegistry } from "../typechain";

async function execute() {
  console.log("Executing");
  const badgeRegistryContract = await ethers.getContractFactory(
    "BadgeRegistry"
  );
  const badgeRegistry1 = await badgeRegistryContract.attach(
    "0x812CD0fdBddA06748DAd23Fa0614b1A13920dC96"
  );

  await badgeRegistry1.setCertifiedRegistry(
    "0x59C98aA670497D5795Eccc154015d2a7Ce76b8dd",
    true
  );

  console.log("Success");
}

execute().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
