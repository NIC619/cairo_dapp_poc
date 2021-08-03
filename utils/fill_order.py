import os
import json
import sys

from gen_order_signatures import gen_order_signature, read_keys

DIR = os.path.dirname(__file__)

def main():
    keys = read_keys()

    tx = {}
    taker_account_id = input("taker account id: ")
    tx["taker_public_key"] = keys["id_to_keys"][taker_account_id]["public_key"]
    print(f"public key of account id {taker_account_id}: {tx['taker_public_key']}")
    tx["taker_token_id"] = int(input("taker token id: "))
    tx["taker_token_amount"] = int(input("taker token amount: "))
    maker_account_id = input("maker account id: ")
    tx["maker_public_key"] = keys["id_to_keys"][maker_account_id]["public_key"]
    print(f"public key of account id {maker_account_id}: {tx['maker_public_key']}")
    tx["maker_token_id"] = int(input("maker token id: "))
    tx["maker_token_amount"] = int(input("maker token amount: "))
    tx["salt"] = int(input("salt: "))

    tx_with_sig = gen_order_signature(keys, tx)
    print(f"Signature for Order(")
    print(f"   taker_public_key={tx_with_sig['taker_public_key']}")
    print(f"   taker_token_id={tx_with_sig['taker_token_id']}")
    print(f"   taker_token_amount={tx_with_sig['taker_token_amount']}")
    print(f"   maker_public_key={tx_with_sig['maker_public_key']}")
    print(f"   maker_token_id={tx_with_sig['maker_token_id']}")
    print(f"   maker_token_amount={tx_with_sig['maker_token_amount']}\n)")
    print(f"r_a: {tx_with_sig['r_a']}")
    print(f"s_a: {tx_with_sig['s_a']}")
    print(f"r_b: {tx_with_sig['r_b']}")
    print(f"s_b: {tx_with_sig['s_b']}")
    print(f"salt: {tx_with_sig['salt']}")

if __name__ == "__main__":
    sys.exit(main())