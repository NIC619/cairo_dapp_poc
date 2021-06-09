import os
import json
import sys

from starkware.crypto.signature.signature import (
    pedersen_hash, sign)

from gen_keys import left_pad_hex_string

DIR = os.path.dirname(__file__)

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

def gen_tx_signature(keys, txs):
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
        tx["r_a"] = left_pad_hex_string(hex(r))
        tx["s_a"] = left_pad_hex_string(hex(s))

        r, s = sign(
            msg_hash=tx_hash,
            priv_key=keys[maker_id]["private_key"])
        tx["r_b"] = left_pad_hex_string(hex(r))
        tx["s_b"] = left_pad_hex_string(hex(s))

    return txs