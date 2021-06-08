import { expect } from "chai"
import { ethers, network } from "hardhat"
import { Contract, Signer, Wallet } from "ethers"

export function parseLogs(contract: Contract, eventName: string, logs) {
    let event = contract.interface.getEvent(eventName)
    let topic = contract.interface.getEventTopic(eventName)

    return logs
        .filter((log) => log.topics[0] == topic && contract.address == log.address)
        .map((log) => contract.interface.parseLog(log))
}

describe("FillOrder", function () {
    // Roles
    let operator: Signer, operatorAddress: string
    let user: Signer, userAddress: string

    // Contracts
    let fillOrder: Contract

    before(async () => {
        [user, operator] = await ethers.getSigners()
        userAddress = await user.getAddress()
        operatorAddress = await operator.getAddress()

        const stateTreeRoot = "0x07c4a7bcaa8f61d92ea404ad63b3bba15607dec4981ccf27f201f22a0d1b4bbb"
        const programHash = "0x06c4cf2c0243a767fb52890c415f68a080e1231c852f2e0cb8b78f2bea200a11"
        // const verifierAddress = ""
        const accountIds = [0, 0, 5, 5, 8, 8]
        const accountTokenIds = [99, 133, 99, 133, 99, 133]
        const accountTokenBalances = [1000000, 5000000, 7500000, 200000, 45000, 11100]
        fillOrder = await (await ethers.getContractFactory(
            "FillOrder",
            operator,
        )).deploy(
            stateTreeRoot,
            programHash,
            // verifierAddress,
            accountIds,
            accountTokenIds,
            accountTokenBalances
        )
    })

    it("Should update state", async () => {
        expect(await fillOrder.callStatic.tokenBalance(0, 99)).to.equal(1000000)
        expect(await fillOrder.callStatic.tokenBalance(8, 133)).to.equal(11100)
        expect(await fillOrder.callStatic.stateTreeRoot()).to.equal("0x07c4a7bcaa8f61d92ea404ad63b3bba15607dec4981ccf27f201f22a0d1b4bbb")

        const transactions = [
            {
                "takerAccountId": 0,
                "takerTokenId": 99,
                "takerTokenAmount": 400000,
                "makerAccountId": 5,
                "makerTokenId": 133,
                "makerTokenAmount": 70000,
                "salt": 1334,
                "feeAmount": 210,
            },
            {
                "takerAccountId": 5,
                "takerTokenId": 99,
                "takerTokenAmount": 190000,
                "makerAccountId": 0,
                "makerTokenId": 133,
                "makerTokenAmount": 12000,
                "salt": 5566,
                "feeAmount": 36,
            }
        ]
        const newStateRoot = "0x4fa96908bd2687465e809f63762b952be2e4647dc5561f03e58fded23dd266e"
        await fillOrder.connect(operator).updateState(transactions, newStateRoot)

        expect(await fillOrder.callStatic.tokenBalance(0, 99)).to.equal(790000)
        expect(await fillOrder.callStatic.tokenBalance(8, 133)).to.equal(11100)
        expect(await fillOrder.callStatic.stateTreeRoot()).to.equal(newStateRoot)

    })
})