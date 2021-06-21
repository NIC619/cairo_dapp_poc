import os
import json
import sys
import copy

from constants import BPS, FEE_BPS

DIR = os.path.dirname(__file__)

def state_transition(pre_state, transactions):
    balances = pre_state["balances"]
    fee_balances = pre_state["fee_balances"]
    for transaction in transactions:
        taker_public_key = str(transaction["taker_public_key"])
        taker_token_id = str(transaction["taker_token_id"])
        taker_token_amount = transaction["taker_token_amount"]
        maker_public_key = str(transaction["maker_public_key"])
        maker_token_id = str(transaction["maker_token_id"])
        maker_token_amount = transaction["maker_token_amount"]

        assert taker_token_id in balances[taker_public_key]
        assert balances[taker_public_key][taker_token_id] > taker_token_amount

        maker = balances[maker_public_key]
        assert maker_token_id in balances[maker_public_key]
        assert balances[maker_public_key][maker_token_id] > maker_token_amount

        fee_b_amount = (maker_token_amount * FEE_BPS) // BPS

        # Update taker balance
        if maker_token_id not in balances[taker_public_key]:
            balances[taker_public_key][maker_token_id] = 0
        balances[taker_public_key][taker_token_id] -= taker_token_amount
        balances[taker_public_key][maker_token_id] += (maker_token_amount - fee_b_amount)
        # Update maker balance
        if taker_token_id not in balances[maker_public_key]:
            balances[maker_public_key][taker_token_id] = 0
        balances[maker_public_key][taker_token_id] += taker_token_amount
        balances[maker_public_key][maker_token_id] -= maker_token_amount
        # Update fee balance
        if maker_token_id not in fee_balances:
            fee_balances[maker_token_id] = 0
        fee_balances[maker_token_id] += fee_b_amount
    post_state = pre_state
    return post_state

def main():
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    pre_state = input_data["pre_state"]
    txs = input_data["transactions"]

    post_state = state_transition(copy.deepcopy(pre_state), txs)
    input_data["post_state"] = post_state
    with open(file_path, "w") as f:
        json.dump(input_data, f, indent=4)
        f.write("\n")

if __name__ == "__main__":
    sys.exit(main())