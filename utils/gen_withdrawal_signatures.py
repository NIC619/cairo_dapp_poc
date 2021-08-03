import os
import json
import sys

from starkware.crypto.signature.signature import (
    pedersen_hash, sign)

DIR = os.path.dirname(__file__)

def read_keys():
    file_name = "../keys.json"
    file_path = os.path.join(DIR, file_name)
    return json.load(open(file_path))

def main():
    keys = read_keys()
    user_account_id = input("user account id: ")
    user = keys["id_to_keys"][user_account_id]["public_key"]
    token_id = input("token_id: ")
    amount = input("amount: ")
    withdrawal_hash = pedersen_hash(int(token_id), int(amount))
    r, s = sign(
        msg_hash=withdrawal_hash,
        priv_key=keys["pub_key_to_priv_key"][str(user)])
    print(f"user: {user}")
    print(f"token_id: {token_id}")
    print(f"amount: {amount}")
    print(f"sig_r: {r}")
    print(f"sig_s: {s}")

if __name__ == "__main__":
    sys.exit(main())