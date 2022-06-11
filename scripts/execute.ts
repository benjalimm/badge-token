import { ethers } from "hardhat";
import { BadgeRegistry } from "../typechain";

async function execute() {
  console.log("Executing");
  const badgeRegistryContract = await ethers.getContractFactory(
    "BadgeRegistry"
  );
  const badgeRegistry1 = await badgeRegistryContract.attach(
    "0xCBa09006B687089E0f913530bc88aF163231F3B1"
  );

  await badgeRegistry1.setCertifiedRegistry(
    "0x673F5aA8D0296eFbd65526724d360c2BE79Acf8E",
    true
  );

  console.log("Success");
}

execute().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
