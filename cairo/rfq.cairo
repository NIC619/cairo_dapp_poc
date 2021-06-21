%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import (
    assert_nn_le, assert_not_equal, unsigned_div_rem)
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.core.storage.storage import Storage

const MAX_BALANCE = %[ 2**64 - 1 %]

const BPS = 10000
const FEE_BPS = 30

# # Represents a swap transaction between two users.
# struct Order:
#     member taker_public_key : felt
#     member taker_token_id : felt
#     member taker_token_amount : felt
#     member r_a : felt
#     member s_a : felt
#     member maker_public_key : felt
#     member maker_token_id : felt
#     member maker_token_amount : felt
#     member r_b : felt
#     member s_b : felt
#     member salt : felt
# end

# A map from token id to the accrued fee balance of this contract.
@storage_var
func fee_balance(token_id : felt) -> (res : felt):
end

# Returns this contract's accrued fee balance of given token id.
@view
func get_fee_balance{storage_ptr : Storage*, pedersen_ptr : HashBuiltin*}(token_id : felt) -> (res : felt):
    let (res) = fee_balance.read(token_id=token_id)
    return (res)
end

# A map from user (public key) and token id to token balance.
@storage_var
func balance(user : felt, token_id : felt) -> (res : felt):
end

# Returns the balance of the given user.
@view
func get_balance{storage_ptr : Storage*, pedersen_ptr : HashBuiltin*}(user : felt, token_id : felt) -> (res : felt):
    let (res) = balance.read(user=user, token_id=token_id)
    return (res)
end

@external
func deposit{
        storage_ptr : Storage*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*,
        ecdsa_ptr : SignatureBuiltin*}(
        user : felt, token_id : felt, amount : felt, sig_r : felt, sig_s : felt):
    # Verify the user's signature.
    let (deposit_hash) = hash2{hash_ptr=pedersen_ptr}(
        token_id,
        amount)
    verify_ecdsa_signature(message=deposit_hash, public_key=user, signature_r=sig_r, signature_s=sig_s)

    let (current_token_balance) = balance.read(user=user, token_id=token_id)
    let new_token_balance = current_token_balance + amount
    # Check balance overflow
    assert_nn_le(new_token_balance, MAX_BALANCE)

    balance.write(user, token_id, new_token_balance)
    return ()
end

func modify_user_balance{
        storage_ptr : Storage*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(
        public_key : felt, token_id : felt, amount : felt):
    let (current_balance) = balance.read(
        user=public_key, token_id=token_id)
    tempvar new_balance = current_balance + amount
    assert_nn_le(new_balance, MAX_BALANCE - 1)
    balance.write(
        user=public_key,
        token_id=token_id,
        value=new_balance)
    return ()
end

func modify_fee_balance{
        storage_ptr : Storage*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(
        token_id : felt, amount : felt):
    let (current_fee_balance) = fee_balance.read(token_id=token_id)
    tempvar new_balance = current_fee_balance + amount
    assert_nn_le(new_balance, MAX_BALANCE - 1)
    fee_balance.write(
        token_id=token_id,
        value=new_balance)
    return ()
end

# Returns a hash committing to the order using the
# following formula:
#     H(
#         H(
#             H(H(taker_public_key, taker_token_id), taker_token_amount)),
#             H(H(maker_public_key, maker_token_id), token_b_amount))
#         ),
#         salt
#     )
# where H is the Pedersen hash function.
func get_order_hash{pedersen_ptr : HashBuiltin*}(
        taker_public_key : felt,
        taker_token_id : felt,
        taker_token_amount : felt,
        r_a : felt,
        s_a : felt,
        maker_public_key : felt,
        maker_token_id : felt,
        maker_token_amount : felt,
        r_b : felt,
        s_b : felt,
        salt : felt) -> (res : felt):
    let (taker_pubkey_and_id_hash) = hash2{hash_ptr=pedersen_ptr}(
        taker_public_key,
        taker_token_id)
    let (taker_hash) = hash2{hash_ptr=pedersen_ptr}(
        taker_pubkey_and_id_hash,
        taker_token_amount)

    let (maker_pubkey_and_id_hash) = hash2{hash_ptr=pedersen_ptr}(
        maker_public_key,
        maker_token_id)
    let (maker_hash) = hash2{hash_ptr=pedersen_ptr}(
        maker_pubkey_and_id_hash,
        maker_token_amount)

    let (taker_maker_hash) = hash2{hash_ptr=pedersen_ptr}(
        taker_hash, maker_hash)

    return hash2{hash_ptr=pedersen_ptr}(
        taker_maker_hash, salt)
end

@external
func fill_order{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        ecdsa_ptr : SignatureBuiltin*}(
        taker_public_key : felt,
        taker_token_id : felt,
        taker_token_amount : felt,
        r_a : felt,
        s_a : felt,
        maker_public_key : felt,
        maker_token_id : felt,
        maker_token_amount : felt,
        r_b : felt,
        s_b : felt,
        salt : felt):
    alloc_locals

    # tempvar taker_token_amount = taker_token_amount
    # tempvar maker_token_amount = maker_token_amount

    # Check that account id are not the same
    assert_not_equal(
        taker_public_key,
        maker_public_key)
    # Check that amounts are in range.
    assert_nn_le(taker_token_amount, MAX_BALANCE)
    assert_nn_le(maker_token_amount, MAX_BALANCE)

    # Extract fee
    let (fee_b, _) = unsigned_div_rem((maker_token_amount * FEE_BPS), BPS)
    assert_nn_le(fee_b, MAX_BALANCE)

    let (order_hash) = get_order_hash(
        taker_public_key,
        taker_token_id,
        taker_token_amount,
        r_a,
        s_a,
        maker_public_key,
        maker_token_id,
        maker_token_amount,
        r_b,
        s_b,
        salt)

    # Verify taker and maker signature.
    verify_ecdsa_signature(
        message=order_hash,
        public_key=taker_public_key,
        signature_r=r_a,
        signature_s=s_a)
    verify_ecdsa_signature(
        message=order_hash,
        public_key=maker_public_key,
        signature_r=r_b,
        signature_s=s_b)

    # Update the taker and maker balance
    modify_user_balance(
        public_key=taker_public_key,
        token_id=taker_token_id,
        amount=-taker_token_amount)
    modify_user_balance(
        public_key=taker_public_key,
        token_id=maker_token_id,
        amount=(maker_token_amount - fee_b))
    modify_user_balance(
        public_key=maker_public_key,
        token_id=maker_token_id,
        amount=-maker_token_amount)
    modify_user_balance(
        public_key=maker_public_key,
        token_id=taker_token_id,
        amount=taker_token_amount)
    # Update fee balance
    modify_fee_balance(
        token_id=maker_token_id,
        amount=fee_b)

    return ()
end