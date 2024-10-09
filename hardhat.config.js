require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-ignition-ethers");
require("dotenv").config();

dotenv.config();

const { ADMIN_ACCOUNT_PRIVATE_KEY, POLYGON_API_KEY, POLYGON_URL } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    polygon: {
      url: `${POLYGON_URL}`,
      chainId: 137,
      accounts: [`${ADMIN_ACCOUNT_PRIVATE_KEY}`], 
    },
  },
  etherscan: {
    apiKey: {
      polygon: `${POLYGON_API_KEY}`,
    },
  },
};
