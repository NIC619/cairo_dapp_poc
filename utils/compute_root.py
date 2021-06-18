import os
import json
import sys
import copy

from starkware.cairo.lang.vm.crypto import pedersen_hash
from starkware.cairo.common.small_merkle_tree import MerkleTree

from constants import BPS, FEE_BPS, LOG_N_ACCOUNTS, LOG_N_TOKENS
from gen_keys import left_pad_hex_string
from apply_state_transition import state_transition

DIR = os.path.dirname(__file__)

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


def compute_public_key_and_hashes(balances):
    public_keys = []
    account_hashes = []
    for acct_id, acct in balances.items():
        public_keys.append(int(acct_id))
        # print(f'account id {acct_id}: {acct["token_balances"]}')
        account_hashes.append(compute_account_hash(acct["public_key"], acct["token_balances"]))
    # print(f'account hashes: {account_hashes}')
    return public_keys, account_hashes

def compute_merkle_root(public_keys, account_hashes):
    tree = MerkleTree(tree_height=LOG_N_ACCOUNTS, default_leaf=0)
    account_hash_pairs = list(zip(public_keys, account_hashes))
    # print(f'account hash pairs: {account_hash_pairs}')
    tree_root = tree.compute_merkle_root(account_hash_pairs)
    print(f'tree root: {tree_root}')
    return left_pad_hex_string(hex(tree_root))

def compute_root(pre_state, transactions):
    print("pre_state:")
    public_keys, account_hashes = compute_public_key_and_hashes(pre_state["balances"])    
    pre_state_root = compute_merkle_root(public_keys, account_hashes)

    post_state = state_transition(copy.deepcopy(pre_state), transactions)

    print("\npost_state:")
    public_keys, account_hashes = compute_public_key_and_hashes(post_state["balances"])    
    post_state_root = compute_merkle_root(public_keys, account_hashes)

    return pre_state_root, post_state, post_state_root

def main():
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    pre_state = input_data["pre_state"]
    txs = input_data["transactions"]
    compute_root(pre_state, txs)

if __name__ == "__main__":
    sys.exit(main())