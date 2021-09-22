import "dotenv/config";
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-ethers"

const ALCHEMY_TOKEN = process.env.ALCHEMY_TOKEN || ""

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

export default {
  networks: {
    goerli: {
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_TOKEN}`,
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

