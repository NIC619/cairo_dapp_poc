from starkware.cairo.common.dict import (
    DictAccess, dict_read, dict_write)
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.registers import get_fp_and_pc

from cairo.data_struct import (Account, State, MAX_BALANCE)

func update_token_balance{range_check_ptr}(
    account : Account*, token_id, amount_diff) -> (
    account : Account*):
    alloc_locals

    # Define a reference to account.token_balance_dict_end so that we
    # can use it as an implicit argument to the dict functions.
    let token_balance_dict_end = account.token_balance_dict_end

    # Retrieve the pointer to the current state of the account.
    let (local token_balance : felt) = dict_read{
        dict_ptr=token_balance_dict_end}(key=token_id)

    %{
        dict_tracker = __dict_manager.get_tracker(ids.token_balance_dict_end)
        print(f'    token (id {ids.token_id}) balance before: {dict_tracker.data[ids.token_id]}')
    %}

    tempvar new_token_balance = token_balance + amount_diff
    assert_nn_le(new_token_balance, MAX_BALANCE)

    # Perform the balance update.
    dict_write{dict_ptr=token_balance_dict_end}(
        key=token_id, new_value=new_token_balance)

    %{
        dict_tracker = __dict_manager.get_tracker(ids.token_balance_dict_end)
        print(f'    token (id {ids.token_id}) balance after: {dict_tracker.data[ids.token_id]}')
    %}

    local new_account : Account
    assert new_account.public_key = account.public_key
    assert new_account.token_balance_dict_start = (
        account.token_balance_dict_start)
    assert new_account.token_balance_dict_end = token_balance_dict_end

    let (__fp__, _) = get_fp_and_pc()
    return (account=&new_account)
end

func update_account{range_check_ptr}(
        state : State, account_id,
        token_a_id, amount_a_diff,
        token_b_id, amount_b_diff) -> (
        state : State, pub_key):
    alloc_locals

    # Define a reference to state.account_dict_end so that we
    # can use it as an implicit argument to the dict functions.
    let account_dict_end = state.account_dict_end

    # Retrieve the pointer to the current state of the account.
    let (local old_account : Account*) = dict_read{
        dict_ptr=account_dict_end}(key=account_id)

    let (new_account) = update_token_balance(
        old_account,
        token_a_id,
        amount_a_diff)
    
    let (new_account) = update_token_balance(
        new_account, # need to use updated `new_account` instead of `old_account`
        token_b_id,
        amount_b_diff)

    # Perform the account update.
    dict_write{dict_ptr=account_dict_end}(
        key=account_id, new_value=cast(new_account, felt))

    # Construct and return the new state.
    local new_state : State
    assert new_state.account_dict_start = (
        state.account_dict_start)
    assert new_state.account_dict_end = account_dict_end

    return (state=new_state, pub_key=old_account.public_key)
end