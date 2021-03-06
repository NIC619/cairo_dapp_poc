import os
import json

DIR = os.path.dirname(__file__)
file_name = "../keys.json"
file_path = os.path.join(DIR, file_name)

def left_pad_hex_string(str, length = 64):
    return str[:2] + str[2:].zfill(length)

from starkware.crypto.signature.signature import private_to_stark_key

# Generate key pairs.
keys_data = {}
priv_keys = []
pub_keys = []
id_to_keys = {}
pub_key_to_priv_key = {}

for i in range(10):
    priv_key = 123456 * i + 654321  # See "Safety note" below.
    priv_keys.append(priv_key)

    # pub_key = left_pad_hex_string(
    #     hex(private_to_stark_key(priv_key))
    # )
    pub_key = private_to_stark_key(priv_key)
    pub_keys.append(pub_key)

    id_to_keys[str(i)] = {
        "public_key": pub_key,
        "private_key": priv_key
    }

    pub_key_to_priv_key[pub_key] = priv_key

keys_data["pub_key_to_priv_key"] = pub_key_to_priv_key
keys_data["id_to_keys"] = id_to_keys
keys_data["private_keys"] = priv_keys
keys_data["public_keys"] = pub_keys

# Write the data (private and public keys) to a JSON file.
with open(file_path, 'w') as f:
    json.dump(keys_data, f, indent=4)
    f.write('\n')
