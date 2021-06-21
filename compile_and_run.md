## Compile and run

### Compile the contract

- `starknet-compile cairo/rfq.cairo --output rfq_compiled.json --abi rfq_abi.json`

### Deploy the contract

- `starknet deploy --contract rfq_compiled.json --network alpha`
    - it will output contract address and transaction id, for example:
    ```
    Deploy transaction was sent.
    Contract address: 0x06c5865999170e6ed7f9d0add9dc9684e6b93e390b7b7ec0ebe42f1c9bc49268.
    Transaction ID: 360653.
    ```

- you can query the token balance of given public key
    - to get a user's public key, first generate key files by running `python utils/gen_keys.py` and pick a public key, for example:
    `798472886190004179001673494155360729135078329522332065779728082154055368978`
    - next query the contract, for example:
    ```
    starknet call \
        --address 0x06c5865999170e6ed7f9d0add9dc9684e6b93e390b7b7ec0ebe42f1c9bc49268 \
        --abi rfq_abi.json \
        --function get_balance \
        --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 \
        --network alpha
    ```
    - `--address`: contract address
    - `--inputs` function inputs, for example, `798472886190004179001673494155360729135078329522332065779728082154055368978` is the public key and `0` is the token id
    - it will output this public key's token balance: `0` (all values default to `0`)

- you can query the accrued fee balance
    - for example:
    ```
    starknet call \
        --address 0x06c5865999170e6ed7f9d0add9dc9684e6b93e390b7b7ec0ebe42f1c9bc49268 \
        --abi rfq_abi.json \
        --function get_fee_balance \
        --inputs 3 \
        --network alpha
    ```
    - it will output accrued fee balance of token `3`: `0`

### Invoke the contract

- before making deposits or transactions, create empty input files, for example, `state_and_txs.json`:
```json
{
    "pre_state": {
        "fee_balances": {
        },
        "balances": {
        }
    },
    "transactions": [
    ]
}
``` 
- then make some deposits for different users: `python utils/deposit.py`
    - you will be asked to input user's account_id, token_id and amount to deposit
    - it will output these info alogn with the signature `r` and `s`, for example:
    ```
    Signature for Deposit(token_id=0, amount=1000000):
    r: 2701389540838900302138899080319714673829120111437534574132705441309686971501
    s: 3192400569399595171714691739592657741252462714496744104718595064627615354803
    public key: 798472886190004179001673494155360729135078329522332065779728082154055368978
    ```
        - it will also modify the `state_and_txs.json` file
    - use these deposit infos to invoke `deposit` transactions:
    ```
    starknet invoke \
        --address 0x06c5865999170e6ed7f9d0add9dc9684e6b93e390b7b7ec0ebe42f1c9bc49268 \
        --abi rfq_abi.json \
        --function deposit \
        --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 1000000 \
            2701389540838900302138899080319714673829120111437534574132705441309686971501 \
            3192400569399595171714691739592657741252462714496744104718595064627615354803 \
        --network alpha
    ```
    - this will increase user(with public key `798472886190004179001673494155360729135078329522332065779728082154055368978`)'s token `0` balance by `1000000`
        - you can again query this public key's token balance with the query command mentioned above 
- after you have intial balances for some users, make some transactions with different taker and maker: `python utils/add_transaction.py`
    - you will be asked to input both taker and makers' account_id, token_id and token amount
    - it will output these info alogn with taker and makers' signatures: `r_a`, `s_a`, `r_b` and `s_b`, for example:
    ```
    Signature for Order(
        taker_public_key=798472886190004179001673494155360729135078329522332065779728082154055368978
        taker_token_id=0
        taker_token_amount=60000
        maker_public_key=2068639949689498141675028465542534557279920353989192851652645386548165695517
        maker_token_id=3
        maker_token_amount=13000
    )
    r_a: 3429789314520330877318043178378477543825795005228452990396263075215196199293
    s_a: 1793052393788225838737250408499274905866622278927909545991705968914328310568
    r_b: 3348315341993874715917584417237273879105860144563702552484893292283654746563
    s_b: 8387149487388293086481369701316229656557579982362672389197204303535652127
    ```
        - it will also modify the `state_and_txs.json` file
    - use these transaction infos to invoke `fill_order` transactions:
    ```
    starknet invoke \
        --address 0x06c5865999170e6ed7f9d0add9dc9684e6b93e390b7b7ec0ebe42f1c9bc49268 \
        --abi rfq_abi.json \
        --function fill_order \
        --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 60000 \
            3429789314520330877318043178378477543825795005228452990396263075215196199293 \
            1793052393788225838737250408499274905866622278927909545991705968914328310568 \
            2068639949689498141675028465542534557279920353989192851652645386548165695517 3 13000 \
            3348315341993874715917584417237273879105860144563702552484893292283654746563 \
            8387149487388293086481369701316229656557579982362672389197204303535652127 \
            5566 \
        --network alpha
    ```
    - taker will be user(with public key `798472886190004179001673494155360729135078329522332065779728082154055368978`)
    - taker token will be `0`
    - maker will be user(with public key `2068639949689498141675028465542534557279920353989192851652645386548165695517`)
    - maker token will be `3`
    - this will transfer `60000` taker token from taker to maker and transfer `13000` maker token from maker to taker
        - note that there will be fee charged for maker token so taker will receive less than `13000` maker token
- finally, you can run `python utils/apply_state_transition.py` and apply state transition on `state_and_txs` file
    - it will apply the transactions on `pre_state` and produce `post_state`
    - you can query the token balances of taker and maker or fee token balance to see if they match