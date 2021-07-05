import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

import "@nomiclabs/hardhat-waffle";

// This adds support for TS path mappings
import "tsconfig-paths/register";

import { HardhatUserConfig } from "hardhat/types";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.RPC_URL,
        blockNumber: Number(process.env.BLOCK_NUMBER),
      },
    },
    polygon: {
      url: process.env.MAINNET_RPC_URL,
      accounts: [process.env.MAINNET_ACCOUNT_KEY]
    }
  },
};

export default config;
