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
        taker_public_key = transaction["taker_public_key"]
        taker_token_id = str(transaction["taker_token_id"])
        taker_token_amount = transaction["taker_token_amount"]
        maker_public_key = transaction["maker_public_key"]
        maker_token_id = str(transaction["maker_token_id"])
        maker_token_amount = transaction["maker_token_amount"]

        taker = balances[taker_public_key]
        taker_balance = taker[taker_token_id]
        assert taker_balance >= taker_token_amount

        maker = balances[maker_public_key]
        maker_balance = maker[maker_token_id]
        assert maker_balance >= maker_token_amount

        fee_b_amount = (maker_token_amount * FEE_BPS) // BPS
        
        balances[taker_public_key][taker_token_id] -= taker_token_amount
        balances[taker_public_key][maker_token_id] += (maker_token_amount - fee_b_amount)
        balances[maker_public_key][taker_token_id] += taker_token_amount
        balances[maker_public_key][maker_token_id] -= maker_token_amount
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