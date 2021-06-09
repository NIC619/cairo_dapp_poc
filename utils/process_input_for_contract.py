import json
import os
import sys

from compute_root import compute_root
from constants import BPS, FEE_BPS
from gen_tx_signatures import gen_tx_signature, read_keys

DIR = os.path.dirname(__file__)

def compute_and_add_tx_fees(txs):
    for tx in txs:
        fee_amount = (tx["maker_token_amount"] * FEE_BPS) // BPS
        tx["fee_amount"] = fee_amount
    return txs

def dict_to_list(accounts):
    state_output_data = {}
    account_ids = []
    account_public_keys = []
    account_token_ids = []
    account_token_balances = []
    for account_id_str, info in accounts.items():
        for token_id_str, balance in info["token_balances"].items():
            account_ids.append(int(account_id_str))
            account_public_keys.append(info["public_key"])
            account_token_ids.append(int(token_id_str))
            account_token_balances.append(balance)
    state_output_data["account_ids"] = account_ids
    state_output_data["account_public_keys"] = account_public_keys
    state_output_data["account_token_ids"] = account_token_ids
    state_output_data["account_token_balances"] = account_token_balances
    return state_output_data

def main():
    keys = read_keys()
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    pre_state = input_data["pre_state"]
    txs = input_data["transactions"]

    # txs_with_sigs = gen_tx_signature(keys, txs)

    state_output_data = {}
    state_output_data["pre_state"] = dict_to_list(pre_state["accounts"])

    pre_state_root, post_state, post_state_root = compute_root(pre_state, txs)
    state_output_data["post_state"] = dict_to_list(post_state["accounts"])

    state_output_data["pre_state_root"] = pre_state_root
    state_output_data["post_state_root"] = post_state_root

    txs_output_data = {}
    txs_output_data["transactions"] = compute_and_add_tx_fees(input_data["transactions"])

    txs_output_file_path = os.path.join(DIR, "../txs.json")
    with open(txs_output_file_path, "w") as f:
        json.dump(txs_output_data, f, indent=4)
        f.write("\n")
    state_output_file_path = os.path.join(DIR, "../state.json")
    with open(state_output_file_path, "w") as f:
        json.dump(state_output_data, f, indent=4)
        f.write("\n")

if __name__ == "__main__":
    sys.exit(main())