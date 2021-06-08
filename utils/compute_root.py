import os
import json
import sys
import copy

DIR = os.path.dirname(__file__)

from starkware.cairo.lang.vm.crypto import pedersen_hash
from starkware.cairo.common.small_merkle_tree import MerkleTree

BPS = 10000
FEE_BPS = 30
LOG_N_ACCOUNTS = 10
LOG_N_TOKENS = 10

def state_transition(pre_state, transactions):
    accounts = pre_state["accounts"]
    fees = pre_state["fees"]
    for transaction in transactions:
        taker_id = str(transaction["taker_account_id"])
        taker_token_id = str(transaction["taker_token_id"])
        taker_token_amount = transaction["taker_token_amount"]
        maker_id = str(transaction["maker_account_id"])
        maker_token_id = str(transaction["maker_token_id"])
        maker_token_amount = transaction["maker_token_amount"]

        taker = accounts[taker_id]
        taker_balance = taker["token_balances"][taker_token_id]
        assert taker_balance >= taker_token_amount

        maker = accounts[maker_id]
        maker_balance = maker["token_balances"][maker_token_id]
        assert maker_balance >= maker_token_amount

        fee_b_amount = (maker_token_amount * FEE_BPS) // BPS
        
        accounts[taker_id]["token_balances"][taker_token_id] -= taker_token_amount
        accounts[taker_id]["token_balances"][maker_token_id] += (maker_token_amount - fee_b_amount)
        accounts[maker_id]["token_balances"][taker_token_id] += taker_token_amount
        accounts[maker_id]["token_balances"][maker_token_id] -= maker_token_amount
        fees[maker_token_id] += fee_b_amount
    post_state = pre_state
    return post_state

def compute_account_hash(public_key_hex, tokens):
    token_ids = []
    token_balances = []
    for token_id, token_balance in tokens.items():
        token_ids.append(int(token_id))
        token_balances.append(token_balance)
    token_balance_tree = MerkleTree(tree_height=LOG_N_TOKENS, default_leaf=0)
    token_balance_pairs = list(zip(token_ids, token_balances))
    # print(f'token balance pairs: {token_balance_pairs}')
    tree_root = token_balance_tree.compute_merkle_root(token_balance_pairs)
    # print(f'token balance tree root: {tree_root}')
    # print(f'account hash: {pedersen_hash(int(public_key_hex, 16), tree_root)}')
    return pedersen_hash(int(public_key_hex, 16), tree_root)


def compute_account_id_and_hashes(accounts):
    account_ids = []
    account_hashes = []
    for acct_id, acct in accounts.items():
        account_ids.append(int(acct_id))
        # print(f'account id {acct_id}: {acct["token_balances"]}')
        account_hashes.append(compute_account_hash(acct["public_key"], acct["token_balances"]))
    # print(f'account hashes: {account_hashes}')
    return account_ids, account_hashes

def compute_merkle_root(account_ids, account_hashes):
    tree = MerkleTree(tree_height=LOG_N_ACCOUNTS, default_leaf=0)
    account_hash_pairs = list(zip(account_ids, account_hashes))
    # print(f'account hash pairs: {account_hash_pairs}')
    print(f'tree root: {tree.compute_merkle_root(account_hash_pairs)}')

def main():
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    pre_state = input_data["pre_state"]

    print("pre_state:")
    account_ids, account_hashes = compute_account_id_and_hashes(pre_state["accounts"])    
    compute_merkle_root(account_ids, account_hashes)

    transactions = input_data["transactions"]

    post_state = state_transition(copy.deepcopy(pre_state), transactions)

    print("\npost_state:")
    account_ids, account_hashes = compute_account_id_and_hashes(post_state["accounts"])    
    compute_merkle_root(account_ids, account_hashes)

    input_data["post_state"] = post_state
    with open(file_path, "w") as f:
        json.dump(input_data, f, indent=4)
        f.write("\n")

if __name__ == "__main__":
    sys.exit(main())