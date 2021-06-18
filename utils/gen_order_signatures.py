import os
import json
import sys

from starkware.crypto.signature.signature import (
    pedersen_hash, sign)

from gen_keys import left_pad_hex_string

DIR = os.path.dirname(__file__)

def read_keys():
    file_name = "../keys.json"
    file_path = os.path.join(DIR, file_name)
    return json.load(open(file_path))

def compute_tx_hash(taker_public_key, taker_token_id, taker_token_amount, maker_public_key, maker_token_id, maker_token_amount, salt):
    taker_hash = pedersen_hash(
        pedersen_hash(int(taker_public_key, 16), taker_token_id),
        taker_token_amount
    )
    maker_hash = pedersen_hash(
        pedersen_hash(int(maker_public_key, 16), maker_token_id),
        maker_token_amount
    )
    taker_maker_hash = pedersen_hash(taker_hash, maker_hash)
    return pedersen_hash(taker_maker_hash, salt)

def gen_order_signature(keys, tx):
    taker_public_key = str(tx["taker_public_key"])
    taker_token_id = tx["taker_token_id"]
    taker_token_amount = tx["taker_token_amount"]
    maker_public_key = str(tx["maker_public_key"])
    maker_token_id = tx["maker_token_id"]
    maker_token_amount = tx["maker_token_amount"]
    salt = tx["salt"]
    tx_hash = compute_tx_hash(
        taker_public_key,
        taker_token_id,
        taker_token_amount,
        maker_public_key,
        maker_token_id,
        maker_token_amount,
        salt)

    r, s = sign(
        msg_hash=tx_hash,
        priv_key=keys["pub_key_to_priv_key"][taker_public_key])
    tx["r_a"] = left_pad_hex_string(hex(r))
    tx["s_a"] = left_pad_hex_string(hex(s))

    r, s = sign(
        msg_hash=tx_hash,
        priv_key=keys["pub_key_to_priv_key"][maker_public_key])
    tx["r_b"] = left_pad_hex_string(hex(r))
    tx["s_b"] = left_pad_hex_string(hex(s))
    return tx

def gen_order_signatures(keys, txs):
    txs_with_sigs = []
    for tx in txs:
        txs_with_sigs.append(gen_order_signature(keys, tx))

    return txs_with_sigs

def main():
    keys = read_keys()
    file_name = input("input file name: ")
    file_path = os.path.join(DIR, "../" + file_name + ".json")
    input_data = json.load(open(file_path))
    txs = input_data["transactions"]
    txs_with_sig = gen_order_signatures(keys, txs)
    input_data["transactions"] = txs_with_sig
    with open(file_path, "w") as f:
        json.dump(input_data, f, indent=4)
        f.write("\n")

if __name__ == "__main__":
    sys.exit(main())