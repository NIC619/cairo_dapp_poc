from starkware.cairo.common.cairo_builtins import (
    HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.math import (
    assert_nn_le, assert_not_equal, unsigned_div_rem)

from cairo.data_struct import (
    BPS, FEE_BPS, FeeOutput, MAX_BALANCE, Account, State, SwapTransaction)
from cairo.update_account import update_account
from cairo.verify_tx_signature import verify_tx_signature

func swap{
        output_ptr : felt*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*,
        ecdsa_ptr : SignatureBuiltin*}(
        state : State, transaction : SwapTransaction*) -> (
        state : State):
    alloc_locals

    tempvar taker_token_amount = transaction.taker_token_amount
    tempvar maker_token_amount = transaction.maker_token_amount

    # Check that account id are not the same
    assert_not_equal(
        transaction.taker_account_id,
        transaction.maker_account_id)
    # Check that amounts are in range.
    assert_nn_le(taker_token_amount, MAX_BALANCE)
    assert_nn_le(maker_token_amount, MAX_BALANCE)

    # Extract fee
    let (fee_b, _) = unsigned_div_rem((maker_token_amount * FEE_BPS), BPS)
    assert_nn_le(fee_b, MAX_BALANCE)

    # Update the users' account.
    %{
        # Print the transaction values using a hint, for
        # debugging purposes.
        print(
            f'Order data ---------------------------------\n'
            f'Taker: {ids.transaction.taker_account_id}\n'
            f'Taker token: {ids.transaction.taker_token_id}\n'
            f'Taker token amount: {ids.taker_token_amount}\n'
            f'Maker: {ids.transaction.maker_account_id}\n'
            f'Maker token: {ids.transaction.maker_token_id}\n'
            f'Maker token amount: {ids.maker_token_amount}\n'
            f'--------------------------------------------')
        print(f'Fee charged for maker token (id {ids.transaction.maker_token_id}): {ids.fee_b}')
        print(f'Updating taker account (id {ids.transaction.taker_account_id}):')
    %}
    let (state, pub_key_a) = update_account(
        state=state,
        account_id=transaction.taker_account_id,
        token_a_id=transaction.taker_token_id,
        amount_a_diff=-taker_token_amount,
        token_b_id=transaction.maker_token_id,
        amount_b_diff=(maker_token_amount - fee_b))

    %{
        print(f'Updating maker account (id {ids.transaction.maker_account_id}):')
    %}
    let (state, pub_key_b) = update_account(
        state=state,
        account_id=transaction.maker_account_id,
        token_a_id=transaction.taker_token_id,
        amount_a_diff=taker_token_amount,
        token_b_id=transaction.maker_token_id,
        amount_b_diff=-maker_token_amount)

    %{
        print(f'--------------------------------------------')
        print(f'Update taker/maker balance complete')
    %}
    verify_tx_signature(
        transaction,
        pub_key_a,
        pub_key_b)

    # Write the fee amount to the output.
    let output = cast(output_ptr, FeeOutput*)
    let output_ptr = output_ptr + FeeOutput.SIZE
    assert output.amount = fee_b

    return (state=state)
end

func transaction_loop{
        output_ptr : felt*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*,
        ecdsa_ptr : SignatureBuiltin*}(
        state : State, transactions : SwapTransaction**,
        n_transactions) -> (state : State):
    if n_transactions == 0:
        return (state=state)
    end

    let first_transaction : SwapTransaction* = [transactions]
    let (state) = swap(
        state=state, transaction=first_transaction)

    return transaction_loop(
        state=state,
        transactions=transactions + 1,
        n_transactions=n_transactions - 1)
end