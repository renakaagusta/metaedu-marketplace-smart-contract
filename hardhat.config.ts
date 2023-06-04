import "dotenv/config"; 
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-ethernal";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
        },
      },
    },
  },
  networks: {
    hardhat: {
      chainId: Number(process.env.LOCALHOST_CHAIN_ID),
      mining: {
        auto: false,
        interval: 10000
      }
    },
    localhost: {
      url: process.env.LOCALHOST_URL,
      chainId: Number(process.env.LOCALHOST_CHAIN_ID)
    },
    // sepolia: {
    //   url: process.env.INFURA_SEPOLIA_URL,
    //   accounts: [process.env.INFURA_SEPOLIA_PRIVATE_KEY] 
    // },
  },
  ethernal: {
    email: process.env.ETHERNAL_EMAIL,
    password: process.env.ETHERNAL_PASSWORD,
    disableSync: false, // If set to true, plugin will not sync blocks & txs
    disableTrace: false, // If set to true, plugin won't trace transaction
    workspace: undefined, // Set the workspace to use, will default to the default workspace (latest one used in the dashboard). It is also possible to set it through the ETHERNAL_WORKSPACE env variable
    uploadAst: true, // If set to true, plugin will upload AST, and you'll be able to use the storage feature (longer sync time though)
    disabled: false, // If set to true, the plugin will be disabled, nohting will be synced, ethernal.push won't do anything either
    resetOnStart: undefined, // Pass a workspace name to reset it automatically when restarting the node, note that if the workspace doesn't exist it won't error
    serverSync: false, // Only available on public explorer plans - If set to true, blocks & txs will be synced by the server. For this to work, your chain needs to be accessible from the internet. Also, trace won't be synced for now when this is enabled.
    skipFirstBlock: false, // If set to true, the first block will be skipped. This is mostly useful to avoid having the first block synced with its tx when starting a mainnet fork
    verbose: true // If set to true, will display this config object on start and the full error object
  }
};

export default config;
