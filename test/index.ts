import { expect } from "chai";
import { ethers } from "hardhat";

const ownerAddress = "0x15eDb84992cd6E3ed4f0461B0Fbe743AbD1eA7b5";
const secondUserAddress = "0xaFCA5863FA18E557815d3F45Bd56CbD090106cc8";
// describe("Greeter", function () {
//   it("Should return the new greeting once it's changed", async function () {
//     const Greeter = await ethers.getContractFactory("BadgeRegistry");
//     const greeter = await Greeter.deploy("Hello, world!");
//     await greeter.deployed();

//     expect(await greeter.greet()).to.equal("Hello, world!");

//     const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

//     // wait until the transaction is mined
//     await setGreetingTx.wait();

//     expect(await greeter.greet()).to.equal("Hola, mundo!");
//   });
// });
