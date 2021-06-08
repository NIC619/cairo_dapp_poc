from starkware.cairo.common.dict import DictAccess

# The maximum amount of token.
const MAX_BALANCE = %[ 2**64 - 1 %]

const BPS = 10000
const FEE_BPS = 30

struct Account:
    member public_key : felt
    # A dictionary that tracks the account's token balances.
    member token_balance_dict_start : DictAccess*
    member token_balance_dict_end : DictAccess*
end

struct State:
    # A dictionary that tracks the accounts' state.
    member account_dict_start : DictAccess*
    member account_dict_end : DictAccess*
end

# Represents a swap transaction between two users.
struct SwapTransaction:
    member taker_account_id : felt
    member taker_token_id : felt
    member taker_token_amount : felt
    member r_a : felt
    member s_a : felt
    member maker_account_id : felt
    member maker_token_id : felt
    member maker_token_amount : felt
    member r_b : felt
    member s_b : felt
    member salt : felt
end

#
# The output of the program.
#
struct FeeOutput:
    member amount : felt
end

struct TransactionOutput:
    member taker_account_id : felt
    member taker_token_id : felt
    member taker_token_amount : felt
    member maker_account_id : felt
    member maker_token_id : felt
    member maker_token_amount : felt
    member salt : felt
end

struct MerkleRootsOutput:
    # The account Merkle roots before and after applying
    # the batch.
    member account_root_before : felt
    member account_root_after : felt
end