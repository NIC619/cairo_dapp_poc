from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.dict import (
    DictAccess, dict_new, dict_squash, dict_update)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.small_merkle_tree import (
    small_merkle_tree)

from cairo.data_struct import (Account, State)

const LOG_N_ACCOUNTS = 10
const LOG_N_TOKENS = 10

# For each entry in the input dict (represented by dict_start
# and dict_end) write an entry to the output dict (represented by
# hash_dict_start and hash_dict_end) and keeping the same key.
func update_token_balance_dict_values{pedersen_ptr : HashBuiltin*}(
        dict_start : DictAccess*, dict_end : DictAccess*,
        hash_dict_start : DictAccess*) -> (
        hash_dict_end : DictAccess*):
    if dict_start == dict_end:
        return (hash_dict_end=hash_dict_start)
    end

    # Add an entry to the output dict.
    dict_update{dict_ptr=hash_dict_start}(
        key=dict_start.key,
        prev_value=dict_start.prev_value,
        new_value=dict_start.new_value)
    return update_token_balance_dict_values(
        dict_start=dict_start + DictAccess.SIZE,
        dict_end=dict_end,
        hash_dict_start=hash_dict_start)
end

# Returns a hash committing to the account's token balance tree
func hash_account{pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account_id : felt, account : Account*) -> (account_hash_before, account_hash_after):
    alloc_locals

    # Squash the token balance dictionary.
    let (squashed_dict_start, squashed_dict_end) = dict_squash(
        dict_accesses_start=account.token_balance_dict_start,
        dict_accesses_end=account.token_balance_dict_end)
    local range_check_ptr = range_check_ptr

    # Hash the dict values.
    %{
        from starkware.crypto.signature.signature import pedersen_hash

        token_balances = initial_account_dict[str(ids.account_id)]["token_balances"]
        initial_dict = {
            int(token_id_str): balance
            for token_id_str, balance in token_balances.items()
        }

        del token_balances

        print("token balances:")
        print("initial_dict:")
        print(initial_dict)
    %}
    let (local hash_dict_start : DictAccess*) = dict_new()
    let (hash_dict_end) = update_token_balance_dict_values(
        dict_start=squashed_dict_start,
        dict_end=squashed_dict_end,
        hash_dict_start=hash_dict_start)

    # Compute the two Merkle roots.
    let (root_before, root_after) = small_merkle_tree{
        hash_ptr=pedersen_ptr}(
        squashed_dict_start=hash_dict_start,
        squashed_dict_end=hash_dict_end,
        height=LOG_N_TOKENS)
    let (account_hash_before) = hash2{hash_ptr=pedersen_ptr}(
        account.public_key, root_before)
    let (account_hash_after) = hash2{hash_ptr=pedersen_ptr}(
        account.public_key, root_after)

    return (account_hash_before=account_hash_before, account_hash_after=account_hash_after)
end

# For each entry in the input dict (represented by dict_start
# and dict_end) write an entry to the output dict (represented by
# hash_dict_start and hash_dict_end) after applying hash_account
# on prev_value and new_value and keeping the same key.
func hash_account_dict_values{pedersen_ptr : HashBuiltin*, range_check_ptr}(
        dict_start : DictAccess*, dict_end : DictAccess*,
        hash_dict_start : DictAccess*) -> (
        hash_dict_end : DictAccess*):
    if dict_start == dict_end:
        return (hash_dict_end=hash_dict_start)
    end

    # Compute the hash of the account before and after the
    # change.
    let (account_hash_before, account_hash_after) = hash_account(
        account_id=dict_start.key,
        account=cast(dict_start.new_value, Account*))
    %{
        print(f'hashed account: {ids.dict_start.key}, {ids.account_hash_before}, {ids.account_hash_after}')
    %}

    # Add an entry to the output dict.
    dict_update{dict_ptr=hash_dict_start}(
        key=dict_start.key,
        prev_value=account_hash_before,
        new_value=account_hash_after)
    return hash_account_dict_values(
        dict_start=dict_start + DictAccess.SIZE,
        dict_end=dict_end,
        hash_dict_start=hash_dict_start)
end

# Computes the Merkle roots before and after the batch.
# Hint argument: initial_account_dict should be a dictionary
# from account_id to an address in memory of the Account struct.
func compute_merkle_roots{
        pedersen_ptr : HashBuiltin*, range_check_ptr}(
        state : State) -> (root_before, root_after):
    alloc_locals

    # Squash the account dictionary.
    let (squashed_dict_start, squashed_dict_end) = dict_squash(
        dict_accesses_start=state.account_dict_start,
        dict_accesses_end=state.account_dict_end)
    local range_check_ptr = range_check_ptr

    # Hash the dict values.
    %{
        from starkware.cairo.common.small_merkle_tree import MerkleTree
        from starkware.crypto.signature.signature import pedersen_hash

        def compute_account_hash(public_key_hex, tokens):
            token_ids = []
            token_balances = []
            for token_id, token_balance in tokens.items():
                token_ids.append(int(token_id))
                token_balances.append(token_balance)
            token_balance_tree = MerkleTree(tree_height=ids.LOG_N_TOKENS, default_leaf=0)
            token_balance_pairs = list(zip(token_ids, token_balances))
            # print(f'token balance pairs: {token_balance_pairs}')
            tree_root = token_balance_tree.compute_merkle_root(token_balance_pairs)
            # print(f'tree root: {tree_root}')
            return pedersen_hash(int(public_key_hex, 16), tree_root)

        initial_dict = {}
        for account_id_str, account in initial_account_dict.items():
            initial_dict[int(account_id_str)] = compute_account_hash(account["public_key"], account["token_balances"])
    %}
    let (local hash_dict_start : DictAccess*) = dict_new()
    let (hash_dict_end) = hash_account_dict_values(
        dict_start=squashed_dict_start,
        dict_end=squashed_dict_end,
        hash_dict_start=hash_dict_start)
    local range_check_ptr = range_check_ptr

    # Compute the two Merkle roots.
    let (root_before, root_after) = small_merkle_tree{
        hash_ptr=pedersen_ptr}(
        squashed_dict_start=hash_dict_start,
        squashed_dict_end=hash_dict_end,
        height=LOG_N_ACCOUNTS)

    return (root_before=root_before, root_after=root_after)
end