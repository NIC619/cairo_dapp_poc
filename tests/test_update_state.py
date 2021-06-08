#!/usr/bin/python3
import brownie

def test_update_state(accounts, fill_order):
    assert fill_order.tokenBalance(0, 99) == 1000000
    assert fill_order.tokenBalance(8, 133) == 11100
    assert fill_order.stateTreeRoot() == 3513649642851389103528329536082144519835916108258125939543239512794009914299

    transactions = [
        {
            "takerAccountId": 0,
            "takerTokenId": 99,
            "takerTokenAmount": 400000,
            "makerAccountId": 5,
            "makerTokenId": 133,
            "makerTokenAmount": 70000,
            "salt": 1334,
        },
        {
            "takerAccountId": 5,
            "takerTokenId": 99,
            "takerTokenAmount": 190000,
            "makerAccountId": 0,
            "makerTokenId": 133,
            "makerTokenAmount": 12000,
            "salt": 5566,
        }
    ]
    new_state_root = 2252002319436965673537320875970562059641865197097007355988057426387825141358
    tx = fill_order.updateState(
        transactions,
        new_state_root,
        {'from': accounts[0]}
    )

    assert len(tx.events) == 1
    assert tx.events["UpdateState"].values() == [0x29f7920763cec19bcfef69c195d94b260c8fcc01ecdac22ceaad53689539adbe]
    assert fill_order.tokenBalance(0, 99) == 790000
    assert fill_order.tokenBalance(8, 133) == 11100
    assert fill_order.stateTreeRoot() == 2252002319436965673537320875970562059641865197097007355988057426387825141358
