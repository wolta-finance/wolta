import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";

// This adds support for TS path mappings
import "tsconfig-paths/register";

import { HardhatUserConfig } from "hardhat/types";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.7.6",
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
      gas: 12450000,
    },
  },
};

export default config;
