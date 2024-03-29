import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-contract-sizer";
import fs from "fs";

dotenv.config();
const privateKey = fs.readFileSync(".secret").toString();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    hardhat: {
      chainId: 1337,
    },
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/9c0e4231c73e40da8c90be9e43411cd6",
      accounts: [privateKey],
    },
    polygonMainnet: {
      url: "https://polygon-mainnet.infura.io/v3/9c0e4231c73e40da8c90be9e43411cd6",
    },
    optimisticKovan: {
      url: "https://optimism-kovan.infura.io/v3/9c0e4231c73e40da8c90be9e43411cd6",
      accounts: [privateKey],
    },
    optimismMainnet: {
      url: "https://optimism-mainnet.infura.io/v3/9c0e4231c73e40da8c90be9e43411cd6",
      accounts: [privateKey],
    },
    ethereumRinkeby: {
      url: "https://rinkeby.infura.io/v3/9c0e4231c73e40da8c90be9e43411cd6",
      accounts: [privateKey],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};

export default config;
