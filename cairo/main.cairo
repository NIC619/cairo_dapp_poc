%builtins output pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.dict import (
    DictAccess, dict_new, dict_squash, dict_update)

from cairo.compute_merkle_roots import compute_merkle_roots
from cairo.data_struct import (
    Account, MerkleRootsOutput, State, MAX_BALANCE, SwapTransaction)
from cairo.swap_tokens import transaction_loop


func get_transactions() -> (
        transactions : SwapTransaction**, n_transactions : felt):
    alloc_locals
    local transactions : SwapTransaction**
    local n_transactions : felt
    %{
        transactions = [
            [
                transaction['taker_account_id'],
                transaction['taker_token_id'],
                transaction['taker_token_amount'],
                int(transaction['r_a'], 16),
                int(transaction['s_a'], 16),
                transaction['maker_account_id'],
                transaction['maker_token_id'],
                transaction['maker_token_amount'],
                int(transaction['r_b'], 16),
                int(transaction['s_b'], 16),
                transaction['salt'],
            ]
            for transaction in program_input['transactions']
        ]
        ids.transactions = segments.gen_arg(transactions)
        ids.n_transactions = len(transactions)
    %}
    return (
        transactions=transactions,
        n_transactions=n_transactions)
end

func get_token_balance_dict(account_id : felt) -> (token_balance_dict : DictAccess*):
    alloc_locals
    %{
        pre_state = program_input['pre_state']
        account = pre_state['accounts'][str(ids.account_id)]
        token_balances = account["token_balances"]
        initial_dict = {
            int(token_id_str): balance
            for token_id_str, balance in token_balances.items()
        }

        del account
        del token_balances
    %}

    # Initialize token balance dictionary for the account.
    let (token_balance_dict) = dict_new()
    return (token_balance_dict=token_balance_dict)
end

func init_token_balance_loop(account_ids : felt*, n_accounts : felt) -> ():
    if n_accounts == 0:
        return ()
    end

    let first_account_id : felt = [account_ids]
    let (token_balance_dict) = get_token_balance_dict(account_id=first_account_id)

    %{
        init_token_balance_dict[ids.first_account_id] = ids.token_balance_dict
    %}

    return init_token_balance_loop(
        account_ids=account_ids + 1,
        n_accounts=n_accounts - 1)
end

func get_account_dict() -> (account_dict : DictAccess*):
    alloc_locals
    local account_ids : felt*
    local n_accounts : felt
    %{
        pre_state = program_input['pre_state']
        accounts = pre_state['accounts']
        account_ids = [
            int(account_id_str)
            for account_id_str, _ in accounts.items()
        ]
        ids.account_ids = segments.gen_arg(account_ids)
        ids.n_accounts = len(account_ids)

        init_token_balance_dict = {}

        # Save a copy initial account dict for
        # compute_merkle_roots.
        initial_account_dict = dict(accounts)
    %}
    init_token_balance_loop(account_ids=account_ids, n_accounts=n_accounts)

    %{
        initial_dict = {
            int(account_id_str): segments.gen_arg([
                int(account_info['public_key'], 16),
                init_token_balance_dict[int(account_id_str)].address_,
                init_token_balance_dict[int(account_id_str)].address_,
            ])
            for account_id_str, account_info in accounts.items()
        }

        del init_token_balance_dict
    %}

    # Initialize the account dictionary.
    let (account_dict) = dict_new()
    return (account_dict=account_dict)
end

func main{
        output_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr, ecdsa_ptr : SignatureBuiltin*}():
    alloc_locals

    # Create the initial state.
    local state : State

    let (account_dict) = get_account_dict()
    assert state.account_dict_start = account_dict
    assert state.account_dict_end = account_dict

    # Execute the transactions.
    let (transactions, n_transactions) = get_transactions()
    let (state : State) = transaction_loop(
        state=state,
        transactions=transactions,
        n_transactions=n_transactions)      
    local output_ptr : felt* = output_ptr

    local ecdsa_ptr : SignatureBuiltin* = ecdsa_ptr

    let output = cast(output_ptr, MerkleRootsOutput*)
    let output_ptr = output_ptr + MerkleRootsOutput.SIZE

    # Write the Merkle roots to the output.
    let (root_before, root_after) = compute_merkle_roots(
        state=state)

    assert output.account_root_before = root_before
    assert output.account_root_after = root_after

    return ()
end