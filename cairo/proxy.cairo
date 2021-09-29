%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.storage import Storage

@contract_interface
namespace IRFQContract:
    func modify_user_balance(public_key : felt, token_id : felt, amount : felt):
    end

    func get_balance(user : felt, token_id : felt) -> (res : felt):
    end
end


@storage_var
func RFQ_CONTRACT_ADDRESS() -> (res : felt):
end

@view
func get_RFQ_CONTRACT_ADDRESS{
        storage_ptr : Storage*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : felt):
    let (res) = RFQ_CONTRACT_ADDRESS.read()
    return (res)
end

@external
func set_RFQ_CONTRACT_ADDRESS{
        storage_ptr : Storage*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(new_RFQ_CONTRACT_ADDRESS : felt):
    RFQ_CONTRACT_ADDRESS.write(new_RFQ_CONTRACT_ADDRESS)
    return ()
end

@external
func call_modify_user_balance{
        syscall_ptr : felt*, storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(
        public_key : felt,
        token_id : felt,
        amount : felt):
    let (rfq_contract_address) = RFQ_CONTRACT_ADDRESS.read()
    IRFQContract.modify_user_balance(
        contract_address=rfq_contract_address,
        public_key=public_key,
        token_id=token_id,
        amount=amount)
    return ()
end

@view
func call_get_balance{
        syscall_ptr : felt*, storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(user : felt, token_id : felt) -> (
        res : felt):
    let (rfq_contract_address) = RFQ_CONTRACT_ADDRESS.read()
    let (res) = IRFQContract.get_balance(
        contract_address=rfq_contract_address,
        user=user,
        token_id=token_id,)
    return (res=res)
end