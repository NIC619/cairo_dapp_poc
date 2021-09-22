import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-ethers"

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

export default {
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    goerli: {
      chainId: 5,
      url: "",
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.7.6",
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

