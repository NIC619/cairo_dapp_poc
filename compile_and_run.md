## Compile and run

### L1 Bridge contract

- L1 Bridge contract `L1Bridge.sol` is deployed at [0x8AA60017c581eD84eeaA800482E18475CC4aF36a](https://ropsten.etherscan.io/address/0xa5ec539a1c7cb71555fe831d6ba18af8665d0245#writeContract)
    - you can deploy `L1Bridge` contract by running `npx hardhat run scripts/deploy_l1_bridge.ts  --network goerli`
    - the constructor takes in the StarkNet Core contract address which is deployed at [0x5e6229F2D4d977d20A50219E521dE6Dd694d45cc](https://goerli.etherscan.io/address/0x5e6229F2D4d977d20A50219E521dE6Dd694d45cc#code)
- You will be using L1 Bridge contract to deposit into and withdraw from L2 contract
    - First, use `deposit` to deposit token into L1 Bridge contract
    - Next, use `depositToL2` to deposit the deposited token in previous step into L2 contract
    - After you are done in L2, use `withdrawFromL2` to withdraw token from L2 contract
    - Finally, use `withdraw` to withdraw the token out of L1 Bridge contract

### L2 RFQ contract

~~L2 RFQ contract is deployed at [0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96](https://voyager.online/contract/0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96)~~
Currently StarkNet state is pruned frequently so don't expect deployed contract to last.

### L2 Proxy contract
This contract is used as a contract to interact with RFQ contract, as a demonstration of L2 contract interoperability.

### Or you can deploy a new set of contracts

#### Compile the proxy contract

- `starknet-compile cairo/proxy.cairo --output proxy_compiled.json --abi proxy_abi.json`

#### Deploy

- `starknet deploy --contract proxy_compiled.json --network alpha`
    - it will output contract address and transaction id, for example:
    ```
    Deploy transaction was sent.
    Contract address: 0x0250df919d12eeabc80dc2a5301faf00a6c371a20136d2a473566d9a531b5217
    Transaction ID: 225622
    ```

#### Compile the RFQ contract

- `starknet-compile cairo/rfq.cairo --output rfq_compiled.json --abi rfq_abi.json`

#### Deploy

- `starknet deploy --contract rfq_compiled.json --network alpha`
    - it will output contract address and transaction id, for example:
    ```
    Deploy transaction was sent.
    Contract address: 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96
    Transaction ID: 203291
    ```

#### Set L1 contract address in RFQ contract

- invoke `set_L1_CONTRACT_ADDRESS` function on RFQ contract with param `new_L1_CONTRACT_ADDRESS`, for example,
    ```
    starknet invoke \
        --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
        --abi rfq_abi.json \
        --function set_L1_CONTRACT_ADDRESS \
        --inputs 791542658165672915894689935354852738633778787178
        --network alpha
    ```
    - `791542658165672915894689935354852738633778787178` is equivalent to `L1Bridge` contract address `0x8AA60017c581eD84eeaA800482E18475CC4aF36a`

#### Set Proxy contract address in RFQ contract

- invoke `set_PROXY_ADDRESS` function on RFQ contract with param `new_PROXY_ADDRESS`, for example,
    ```
    starknet invoke \
        --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
        --abi rfq_abi.json \
        --function set_PROXY_ADDRESS \
        --inputs 1047516477518222647696338136122723034425990527897565148904869650456467165719
        --network alpha
    ```
    - `1047516477518222647696338136122723034425990527897565148904869650456467165719` is equivalent to `Proxy` contract address `0x0250df919d12eeabc80dc2a5301faf00a6c371a20136d2a473566d9a531b5217`

#### Set RFQ contract address in Proxy contract

- invoke `set_RFQ_CONTRACT_ADDRESS` function on RFQ contract with param `new_RFQ_CONTRACT_ADDRESS`, for example,
    ```
    starknet invoke \
        --address 0x0250df919d12eeabc80dc2a5301faf00a6c371a20136d2a473566d9a531b5217 \
        --abi proxy_abi.json \
        --function set_RFQ_CONTRACT_ADDRESS \
        --inputs 1717845306189357578435387280039482404771276467351697267262645591057254153110
        --network alpha
    ```
    - `1717845306189357578435387280039482404771276467351697267262645591057254153110` is equivalent to `RFQ` contract address `0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96`

#### Set L2 contract address in L1Bridge contract

- Execute `setL2ContractAddress` function on `L1Bridge` contract with param `l2ContractAddress`, for example, `setL2ContractAddress(0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96)`

### Interact with L2 RFQ contract

#### Query token balance

- you can query the token balance of given public key
    - to get a user's public key, first generate key files by running `python utils/gen_keys.py` and pick a public key, for example:
    `798472886190004179001673494155360729135078329522332065779728082154055368978`
    - next query the contract, for example:
    ```
    starknet call \
        --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
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
        --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
        --abi rfq_abi.json \
        --function get_fee_balance \
        --inputs 3 \
        --network alpha
    ```
    - it will output accrued fee balance of token `3`: `0`

#### Deposit into L1 Bridge contract

- Execute `deposit` function on `L1Bridge` contract with params `user`, `token_id` and `amount`, for example, `deposit(798472886190004179001673494155360729135078329522332065779728082154055368978, 0, 90000)`
    - You should see user `798472886190004179001673494155360729135078329522332065779728082154055368978` balance of token `0` increased by `90000`

- Next execute `depositToL2` function on `L1Bridge` contract with the params `user`, `token_id` and `amount`, for example, `deposit(798472886190004179001673494155360729135078329522332065779728082154055368978, 0, 50000)`
    - An `LogMessageToL2` event will be [emitted](https://ropsten.etherscan.io/tx/0xbc3670f77c1400e50d1603fe4751ffe522dee85d03bcc6d5551bea96987b6ec0#eventlog)
    - You should see user `798472886190004179001673494155360729135078329522332065779728082154055368978` balance of token `0` decreased by `50000`
    - And you should see same user's token `0` balance on L2 RFQ contract increased by `50000` after a while

#### FillOrder on L2 RFQ contract

- after you have intial balances for some users, make some transactions with different taker and maker: `python utils/fill_order.py`
    - you will be asked to input both taker and makers' account_id, token_id and token amount
    - it will output these info alogn with taker and makers' signatures: `r_a`, `s_a`, `r_b` and `s_b`, for example:
    ```
    Signature for Order(
        taker_public_key=798472886190004179001673494155360729135078329522332065779728082154055368978
        taker_token_id=0
        taker_token_amount=25000
        maker_public_key=2068639949689498141675028465542534557279920353989192851652645386548165695517
        maker_token_id=3
        maker_token_amount=13000
    )
    r_a: 573492137583788557356199287279059625666118186998594738089426719549349560648
    s_a: 771306360667852711691065060296601992694000050477943070567091820206254433519
    r_b: 2064254691562969742698014619125391865984610209543531798515106496127638701922
    s_b: 149421945404767920002939144321599777772240547870205246088041216987031511301
    ```
    - use these transaction infos to invoke `fill_order` transactions:
    ```
    starknet invoke \
        --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
        --abi rfq_abi.json \
        --function fill_order \
        --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 25000 \
            573492137583788557356199287279059625666118186998594738089426719549349560648 \
            771306360667852711691065060296601992694000050477943070567091820206254433519 \
            2068639949689498141675028465542534557279920353989192851652645386548165695517 3 13000 \
            2064254691562969742698014619125391865984610209543531798515106496127638701922 \
            149421945404767920002939144321599777772240547870205246088041216987031511301 \
            5566 \
        --network alpha
    ```
    - taker will be user(with public key `798472886190004179001673494155360729135078329522332065779728082154055368978`)
    - taker token will be `0`
    - maker will be user(with public key `2068639949689498141675028465542534557279920353989192851652645386548165695517`)
    - maker token will be `3`
    - this will transfer `25000` taker token from taker to maker and transfer `13000` maker token from maker to taker
        - note that there will be fee charged for maker token so taker will receive less than `13000` maker token
    - you can query the token balances of taker and maker or fee token balance to see if they match

#### Withdraw from L2 RFQ contract

- First generate signature for the withdrawal by running `python utils/gen_withdrawal_signatures.py` and input `user`, `token_id` and `amount`
    - it will output these info alogn with the signature `r` and `s`, for example:
    ```
    user: 798472886190004179001673494155360729135078329522332065779728082154055368978
    token_id: 0
    amount: 9000
    sig_r: 3421526596026741579634945633927675292296016187143081405919502027230563915048
    sig_s: 879128241270193654456325855111235964201945669676268913280186830296364751360
    ```

- Next invoke the `withdraw` function on L2 RFQ contract with params `user`, `token_id`, `amount` and `sig_r` and `sig_s`
    ```
    starknet invoke \
        --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
        --abi rfq_abi.json \
        --function withdraw \
        --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 9000 \
            3421526596026741579634945633927675292296016187143081405919502027230563915048 \
            879128241270193654456325855111235964201945669676268913280186830296364751360 \
        --network alpha
    ```
    - You can see the [message sent to L1](https://voyager.online/tx/107858)
- Finally execute the `withdrawFromL2` function on L1 Bridge contract with `user`, `token_id`, `amount`, for example, `withdrawFromL2(798472886190004179001673494155360729135078329522332065779728082154055368978, 0, 9000)`
    - You should see user `798472886190004179001673494155360729135078329522332065779728082154055368978` balance of token `0` increased by `9000`

### Interact with L2 RFQ contract via Proxy contract

- You can modify RFQ contract's user balance directly by invoking `Proxy` contract's `call_modify_user_balance` function, for example,
    ```
    starknet invoke \
        --address 0x0250df919d12eeabc80dc2a5301faf00a6c371a20136d2a473566d9a531b5217 \
        --abi proxy_abi.json \
        --function call_modify_user_balance \
        --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 10000
        --network alpha
    ```
    - this will set token `0` of user `798472886190004179001673494155360729135078329522332065779728082154055368978` to `10000`
    - you can query the token balances of the user to see if it matches, you can query by calling `RFQ` contract,
        ```
        starknet call \
            --address 0x3cc4417c1a8124f7cee57ab011f3a862a4d08bcd1d99aa251baf9aa18057b96 \
            --abi rfq_abi.json \
            --function get_balance \
            --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 \
            --network alpha
        ```
    - or by calling `Proxy` contract,
        ```
        starknet call \
            --address 0x0250df919d12eeabc80dc2a5301faf00a6c371a20136d2a473566d9a531b5217 \
            --abi proxy_abi.json \
            --function call_get_balance \
            --inputs 798472886190004179001673494155360729135078329522332065779728082154055368978 0 \
            --network alpha
        ```