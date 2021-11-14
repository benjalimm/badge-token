import { expect } from "chai";
import { ethers } from "hardhat";

const ownerAddress = "0x15eDb84992cd6E3ed4f0461B0Fbe743AbD1eA7b5";
describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
describe("Entity + Permission token test", () => {
  it("Should successfully deploy an entity and generate a genesis token for the user", async () => {
    // 1. Deploy entity
    console.log("Attempting to deploy entity contract");
    const entity = await ethers.getContractFactory("Entity");
    const entityInstance = await entity.deploy("Entity");
    await entityInstance.deployed();
    const entityAddress = await entityInstance.address;
    console.log("Entity successfully deployed to address: ", entityAddress);

    // 2. Deploy permission token
    console.log("Attempting to deploy permission contract");
    const permissionContract = await ethers.getContractFactory(
      "PermissionToken"
    );
    const permissionToken = await permissionContract.deploy(entityAddress, 0);
    await permissionToken.deployed();
    const permissionTokenAddress = await permissionToken.address;
    console.log(
      "Permission contract successfully deployed to address: ",
      permissionTokenAddress
    );

    // 3. Generate genesis token
    console.log("Attempting to generate genesis token");
    const id = await entityInstance.generateGenesisToken(
      permissionTokenAddress
    );
    console.log("Successfully Generated genesis token with id: ", id);

    // 4. Assign super user
    console.log("Attempting to assign super user");
  });
});
