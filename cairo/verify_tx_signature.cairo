from starkware.cairo.common.cairo_builtins import (
    HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import (
    verify_ecdsa_signature)

from cairo.data_struct import (SwapTransaction, TransactionHashOutput)

# Returns a hash committing to the transaction using the
# following formula:
#     H(
#         H(
#             H(H(taker_account_id, taker_token_id), taker_token_amount)),
#             H(H(maker_account_id, maker_token_id), token_b_amount))
#         ),
#         salt
#     )
# where H is the Pedersen hash function.
func hash_transaction{pedersen_ptr : HashBuiltin*}(
        transaction : SwapTransaction*) -> (res : felt):
    let (taker_pubkey_and_id_hash) = hash2{hash_ptr=pedersen_ptr}(
        transaction.taker_account_id,
        transaction.taker_token_id)
    let (taker_hash) = hash2{hash_ptr=pedersen_ptr}(
        taker_pubkey_and_id_hash,
        transaction.taker_token_amount)

    let (maker_pubkey_and_id_hash) = hash2{hash_ptr=pedersen_ptr}(
        transaction.maker_account_id,
        transaction.maker_token_id)
    let (maker_hash) = hash2{hash_ptr=pedersen_ptr}(
        maker_pubkey_and_id_hash,
        transaction.maker_token_amount)
    let (taker_maker_hash) = hash2{hash_ptr=pedersen_ptr}(
        taker_hash, maker_hash)

    return hash2{hash_ptr=pedersen_ptr}(
        taker_maker_hash, transaction.salt)
end

func verify_tx_signature{
        output_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        ecdsa_ptr : SignatureBuiltin*}(
        transaction : SwapTransaction*, pub_key_a, pub_key_b):
    let (tx_hash) = hash_transaction(transaction)

    # Write the transaction hash to the output.
    let output = cast(output_ptr, TransactionHashOutput*)
    let output_ptr = output_ptr + TransactionHashOutput.SIZE
    assert output.tx_hash = tx_hash

    # Verify a and b's signature
    verify_ecdsa_signature(
        message=tx_hash,
        public_key=pub_key_a,
        signature_r=transaction.r_a,
        signature_s=transaction.s_a)
    verify_ecdsa_signature(
        message=tx_hash,
        public_key=pub_key_b,
        signature_r=transaction.r_b,
        signature_s=transaction.s_b)
    return ()
end