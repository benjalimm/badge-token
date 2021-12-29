import { expect } from "chai";
import { ethers } from "hardhat";

const ownerAddress = "0x15eDb84992cd6E3ed4f0461B0Fbe743AbD1eA7b5";
const secondUserAddress = "0xaFCA5863FA18E557815d3F45Bd56CbD090106cc8";
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
    // 1. Deploy badge contract
    const badgeContract = await ethers.getContractFactory("BadgeV1");
    const badge = await badgeContract.deploy();
    await badge.deployed();
    const badgeAddress = badge.address;

    // 2. Mint genesis token -> Deploy entity
    const genesisTokenContract = await ethers.getContractFactory(
      "GenesisToken"
    );

    const genesisToken = await genesisTokenContract.attach(
      await badge.genesisToken()
    );
    const entityAddress = await genesisToken.mintGenToken(
      "tokenURI",
      "Badge company",
      badgeAddress
    );

    // 3. Assign super user token
    const superUserTokenContract = await ethers.getContractFactory(
      "SuperUserToken"
    );
    const superUserToken = await superUserTokenContract.attach(
      await badge.superUserToken()
    );
    await superUserToken.mintSuperUserToken(
      "tokenURI",
      secondUserAddress,
      "",
      badgeAddress
    );
  });
});
