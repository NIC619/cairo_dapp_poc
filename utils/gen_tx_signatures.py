import os
import json
import sys

DIR = os.path.dirname(__file__)

from starkware.crypto.signature.signature import (
    pedersen_hash, sign)

def read_keys():
    file_name = "../keys.json"
    file_path = os.path.join(DIR, file_name)
    return json.load(open(file_path))

def read_txs(file_name):
    file_path = os.path.join(DIR, file_name)
    input_data = json.load(open(file_path))
    return input_data["transactions"]

def compute_tx_hash(taker_id, taker_token_id, taker_token_amount, maker_id, maker_token_id, maker_token_amount, salt):
    taker_hash = pedersen_hash(
        pedersen_hash(int(taker_id), taker_token_id),
        taker_token_amount
    )
    maker_hash = pedersen_hash(
        pedersen_hash(int(maker_id), maker_token_id),
        maker_token_amount
    )
    taker_maker_hash = pedersen_hash(taker_hash, maker_hash)
    return pedersen_hash(taker_maker_hash, salt)

def main():
    keys = read_keys()
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    txs = input_data["transactions"]

    for tx in txs:
        taker_id = str(tx["taker_account_id"])
        taker_token_id = tx["taker_token_id"]
        taker_token_amount = tx["taker_token_amount"]
        maker_id = str(tx["maker_account_id"])
        maker_token_id = tx["maker_token_id"]
        maker_token_amount = tx["maker_token_amount"]
        salt = tx["salt"]
        tx_hash = compute_tx_hash(
            taker_id,
            taker_token_id,
            taker_token_amount,
            maker_id,
            maker_token_id,
            maker_token_amount,
            salt)

        r, s = sign(
            msg_hash=tx_hash,
            priv_key=keys[taker_id]["private_key"])
        tx["r_a"] = hex(r)
        tx["s_a"] = hex(s)

        r, s = sign(
            msg_hash=tx_hash,
            priv_key=keys[maker_id]["private_key"])
        tx["r_b"] = hex(r)
        tx["s_b"] = hex(s)

    input_data["transactions"] = txs
    with open(file_path, "w") as f:
        json.dump(input_data, f, indent=4)
        f.write("\n")

if __name__ == "__main__":
    sys.exit(main())