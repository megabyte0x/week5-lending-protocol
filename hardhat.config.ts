import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

// const ALCHEMY_HTTP_URL: string | undefined = process.env.ALCHEMY_HTTP_URL;
// const PRIVATE_KEY: string | undefined = process.env.PRIVATE_KEY;
// const POLYGON_SCAN_KEY: string | undefined = process.env.POLYGON_SCAN_KEY;
// if (!ALCHEMY_HTTP_URL) {
//   throw new Error("Please set your ALCHEMY_HTTP_URL in a .env file");
// }
// if (!PRIVATE_KEY) {
//   throw new Error("Please set your PRIVATE_KEY in a .env file");
// }
// if (!POLYGON_SCAN_KEY) {
//   throw new Error("Please set your POLYGON_SCAN_KEY in a .env file");
// }

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    //   mumbai: {
    //     url: ALCHEMY_HTTP_URL || "",
    //     accounts: [PRIVATE_KEY],
    //   },
    // },
    // etherscan: {
    //   apiKey: {
    //     polygonMumbai: POLYGON_SCAN_KEY || "",
    //   },
  },
  gasReporter: {
    currency: "USD",
    enabled: true,
    excludeContracts: [],
    src: "./contracts",
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
