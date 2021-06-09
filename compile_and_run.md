### Compile and run
- compile: `cairo-compile cairo/main.cairo --output fill_order_compiled.json`
- generate keys file: `python utils/gen_keys.py`
- create input files, for example, `first_batch_input.json`:
```json
{
    "pre_state": {
        "fees": {
            "99": 0,
            "133": 0
        },
        "accounts": {
            "0": {
                "public_key": "0x1c3eb6d67f833a9dac3766b2f22d31299875884f3fc84ebc70c322e8fb18112",
                "token_balances": {
                    "99": 1000000,
                    "133": 5000000
                }
            },
            "5": {
                "public_key": "0x4cb42f213ed6dcfadb7b987fd31b2260334cbe404315708d17a2404fbadb11e",
                "token_balances": {
                    "99": 7500000,
                    "133": 200000
                }
            },
            "8": {
                "public_key": "0x529196a1456a35d3ee9138dd7355cb6416fe40deade3adab76f2e66554400ef",
                "token_balances": {
                    "99": 45000,
                    "133": 11100
                }
            }
        }
    },
    "transactions": [
        {
            "taker_account_id": 0,
            "taker_token_id": 99,
            "taker_token_amount": 400000,
            "maker_account_id": 5,
            "maker_token_id": 133,
            "maker_token_amount": 70000,
            "salt": 1334,
        },
        {
            "taker_account_id": 5,
            "taker_token_id": 99,
            "taker_token_amount": 190000,
            "maker_account_id": 0,
            "maker_token_id": 133,
            "maker_token_amount": 12000,
            "salt": 5566,
        }
    ]
}
``` 
- generate transaction signatures for the input: `python utils/gen_tx_signatures.py`
    - this will add "r_a", "s_a", "r_b" and "s_b" to `first_batch_input.json`
- run the program with first batch of transactions: `cairo-run --program=fill_order_compiled.json --print_output --layout=small --program_input=first_batch_input.json --cairo_pie_output fill_order_pie`
    - output should be:
    ```
    Order data ---------------------------------
    Taker: 0
    Taker token: 99
    Taker token amount: 400000
    Maker: 5
    Maker token: 133
    Maker token amount: 70000
    --------------------------------------------
    Fee charged for maker token (id 133): 210
    Updating taker account (id 0):
        token (id 99) balance before: 1000000
        token (id 99) balance after: 600000
        token (id 133) balance before: 5000000
        token (id 133) balance after: 5069790
    Updating maker account (id 5):
        token (id 99) balance before: 7500000
        token (id 99) balance after: 7900000
        token (id 133) balance before: 200000
        token (id 133) balance after: 130000
    --------------------------------------------
    Update taker/maker balance complete
    Order data ---------------------------------
    Taker: 5
    Taker token: 99
    Taker token amount: 190000
    Maker: 0
    Maker token: 133
    Maker token amount: 12000
    --------------------------------------------
    Fee charged for maker token (id 133): 36
    Updating taker account (id 5):
        token (id 99) balance before: 7900000
        token (id 99) balance after: 7710000
        token (id 133) balance before: 130000
        token (id 133) balance after: 141964
    Updating maker account (id 0):
        token (id 99) balance before: 600000
        token (id 99) balance after: 790000
        token (id 133) balance before: 5069790
        token (id 133) balance after: 5057790
    --------------------------------------------
    Update taker/maker balance complete
    Program output:
        0
        99
        400000
        5
        133
        70000
        1334
        210
        5
        99
        190000
        0
        133
        12000
        5566
        36
        -104853145814742110168993247012925585787191107073470760429852543341862106182
        -1366500469229165540160001907124508045981242018234589343985034629748046879123
    ```
    - first eight outputs are data of first transaction
        - `0`, `99` and `400000` being `taker_account_id`, `taker_token_id` and `taker_token_amount` respectively
        - `5`, `133` and `70000` being `maker_account_id`, `maker_token_id` and `maker_token_amount` respectively
        - `1334` is `salt`
        - `210` is fee collected
        - same for next eight outputs
    - `-104853145814742110168993247012925585787191107073470760429852543341862106182` is the pre state root
    - `-1366500469229165540160001907124508045981242018234589343985034629748046879123` is the post state root
    - you can run `python practices/fill_order/utils/compute_root.py` and input `first_batch_input` to see the produced pre/post state tree roots
        - output should be:
        ```
        input file name: first_batch_input
        pre_state:
        tree root: 3513649642851389103528329536082144519835916108258125939543239512794009914299

        post_state:
        tree root: 2252002319436965673537320875970562059641865197097007355988057426387825141358
        ```
        - note that the pre state tree roots (`-104853145814742110168993247012925585787191107073470760429852543341862106182 (mod p)` and `3513649642851389103528329536082144519835916108258125939543239512794009914299 (mod p)`) from both the Cairo program and the script are the same
            - the same applies to post state roots
        - this script will also generate a post state in `first_batch_input.json`, you can use this post state as the pre state for `second_batch_input.json` and add your transactions
    - `--cairo_pie_output` will output a cairo pie file which contains the information you need to generate proof
        - this pie file can be sent to SHARP with command `cairo-sharp submit --cairo_pie PIE_FILE_NAME`
    - you can run `python practices/fill_order/utils/compute_output_and_fact.py` to output program hash, program output and the fact for this round of execution
        - NOTE: program hash will be the same as long as the cairo program remains unchanged, however, fact will change based on the outputs each time
        - output should be like this:
        ```
        program hash: 0x6c4cf2c0243a767fb52890c415f68a080e1231c852f2e0cb8b78f2bea200a11
        program output: [0, 99, 400000, 5, 133, 70000, 1334, 210, 5, 99, 190000, 0, 133, 12000, 5566, 36, 3513649642851389103528329536082144519835916108258125939543239512794009914299, 2252002319436965673537320875970562059641865197097007355988057426387825141358]
        fact: 0x29f7920763cec19bcfef69c195d94b260c8fcc01ecdac22ceaad53689539adbe
        ```
        - note that the pre/post state roots in `program output` is the same as the ones computed in `compute_root.py` script
        - and the fact is computed based on the `program hash` and `program output`
    - to produce inputs that you can send to on-chain verifier contract, run `python utils/process_input_for_contract.py` and input `first_batch_input`
        - this script will produce `state.json` and `txs.json`
            - `state.json` includes state data like state root, account ids, token balances. Note that data besides state root are compiled into lists instead of mapping so that they can be processed by contract
        - check out the test to see how are these two files are being processed and sent to contract
