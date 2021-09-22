import { ethers } from "hardhat"
import { startnetCoreAddr } from "./utils"

async function main() {
    const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY
    if (deployerPrivateKey === undefined) throw Error("Deployer private key not provided")

    const deployer = new ethers.Wallet(deployerPrivateKey, ethers.provider)

    // Deploying L1Bridge
    console.log("Deploying L1Bridge...")
    const L1Bridge = await (
        await ethers.getContractFactory("L1Bridge", {signer: deployer})
    ).deploy(startnetCoreAddr)
    await L1Bridge.deployTransaction.wait()
    console.log(`L1Bridge contract address: ${L1Bridge.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
