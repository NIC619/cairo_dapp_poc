import { expect } from "chai"
import { ethers } from "hardhat"
import { Contract, Signer } from "ethers"

import * as stateJson from "../state.json"
import * as txsJson from "../txs.json"

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

        const stateTreeRoot = stateJson.pre_state_root
        const programHash = "0x06c4cf2c0243a767fb52890c415f68a080e1231c852f2e0cb8b78f2bea200a11"
        fillOrder = await (await ethers.getContractFactory(
            "FillOrder",
            operator,
        )).deploy(
            stateTreeRoot,
            programHash,
            // verifierAddress,
            stateJson.pre_state.account_ids,
            stateJson.pre_state.account_public_keys,
            stateJson.pre_state.account_token_ids,
            stateJson.pre_state.account_token_balances
        )
    })

    it("Should update state", async () => {
        expect(await fillOrder.callStatic.getTokenBalance(0, 99)).to.equal(1000000)
        expect(await fillOrder.callStatic.getTokenBalance(8, 133)).to.equal(11100)
        expect(await fillOrder.callStatic.stateTreeRoot()).to.equal(stateJson.pre_state_root)

        const transactions : any = []
        const txs = txsJson.transactions
        for (const tx of txs) {
            transactions.push(
                {
                    "takerAccountId": tx.taker_account_id,
                    "takerTokenId": tx.taker_token_id,
                    "takerTokenAmount": tx.taker_token_amount,
                    "makerAccountId": tx.maker_account_id,
                    "makerTokenId": tx.maker_token_id,
                    "makerTokenAmount": tx.maker_token_amount,
                    "salt": tx.salt,
                    "feeAmount": tx.fee_amount,
                }
            )
        }

        const newStateRoot = stateJson.post_state_root
        const tx = await fillOrder.connect(operator).updateState(transactions, newStateRoot)
        const receipt = await tx.wait()

        const updateStateEvents = parseLogs(fillOrder, "UpdateState", receipt.logs)
        expect(updateStateEvents.length).to.equal(1)
        const computedFact = updateStateEvents[0].args.fact
        console.log(`Computed fact: ${computedFact}`)

        expect(await fillOrder.callStatic.getTokenBalance(0, 99)).to.equal(790000)
        expect(await fillOrder.callStatic.getTokenBalance(8, 133)).to.equal(11100)
        expect(await fillOrder.callStatic.stateTreeRoot()).to.equal(newStateRoot)
    })
})