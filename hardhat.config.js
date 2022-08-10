require("@nomiclabs/hardhat-waffle");
require('dotenv').config({ path: ".env" });
// require("@nomiclabs/hardhat-etherscan");
// require("@nomiclabs/hardhat-web3");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async (taskArgs, hre,web3) => {
//   const accounts = await hre.ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */


module.exports = {
  networks: {
    hardhat: {
      // forking: {
      //   url: "https://eth-mainnet.alchemyapi.io/v2/"+process.env.MAIN_ALCHEMY,
      //   blockNumber: 14851736
      // },
      // accounts:[
      //   {
      //     privateKey:process.env.FORK_ACCOUNT_PK1,
      //     balance:'100000000000000000000000'
      //   }
      // ]
    },
    local: {
      url: `http://localhost:8545`,
      accounts: [process.env.PK || '']
    },
    mumbai: {
      url: process.env.MUMBAI_RPC,
      accounts: [process.env.PK || '']
    },
    rinkeby: {
      url: process.env.RINKEBY_RPC,
      accounts: [process.env.PK || '']
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
    ],
  },
  etherscan: {
    apiKey:{
      rinkeby:process.env.ETHERSCAN_API_KEY,
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};

