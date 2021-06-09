import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-ethers"

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

export default {
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    hardhat: {
      chainId: 3,
      forking: {
        url: "",
        blockNumber: 12594300
      }
    },
    // mainnet: {
    //   chainId: 1,
    //   url: "",
    // },
    // ropsten: {
    //   chainId: 3,
    //   url: "",
    // }
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
      }
    ]
  }
}

