import os
import json
import sys

from starkware.crypto.signature.signature import (
    pedersen_hash, sign)

from gen_order_signatures import read_keys

DIR = os.path.dirname(__file__)

def gen_deposit_signature(keys, transaction):
    public_key = transaction["public_key"]
    token_id = int(transaction["token_id"])
    amount = int(transaction["amount"])

    priv_key = keys["pub_key_to_priv_key"][public_key]
    tx_hash = pedersen_hash(
        token_id,
        amount
    )
    r, s = sign(
        msg_hash=tx_hash,
        priv_key=priv_key)

    print(f"Signature for Deposit(token_id={token_id}, amount={amount}):")
    print(f"r: {r}")
    print(f"s: {s}")
    print(f"public key: {public_key}")
    return (r, s)

def deposit(prev_state, transaction):
    public_key = transaction["public_key"]
    token_id = transaction["token_id"]
    amount = int(transaction["amount"])

    if "balances" not in prev_state:
        prev_state["balances"] = {}

    balances = prev_state["balances"]
    if public_key in balances:
        if token_id in balances[public_key]:
            balances[public_key][token_id] += amount
        else:
            balances[public_key][token_id] = amount
    else:
        balances[public_key] = {}
        balances[public_key][token_id] = amount

    prev_state["balances"] = balances
    return prev_state

def main():
    keys = read_keys()
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    prev_state = input_data["pre_state"]
    tx = {}
    account_id = input("account id: ")
    tx["public_key"] = str(keys["id_to_keys"][account_id]["public_key"])
    print(f"public key of account id {account_id}: {tx['public_key']}")
    tx["token_id"] = input("token id: ")
    tx["amount"] = input("amount: ")

    gen_deposit_signature(keys, tx)

    new_state = deposit(prev_state, tx)
    input_data["pre_state"] = new_state
    with open(file_path, "w") as f:
        json.dump(input_data, f, indent=4)
        f.write("\n")

if __name__ == "__main__":
    sys.exit(main())