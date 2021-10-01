import os
import pytest, asyncio

from starkware.crypto.signature.signature import (
    pedersen_hash, sign)
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

from utils.gen_order_signatures import compute_tx_hash

# The path to the contract source code.
RFQ_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../cairo/rfq.cairo")
PROXY_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../cairo/proxy.cairo")

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope='session')
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    yield await Starknet.empty()

@pytest.fixture(scope='function')
async def rfq_contract(starknet):
    # Deploy the rfq_contract.
    rfq_contract = await starknet.deploy(RFQ_CONTRACT_FILE)
    yield rfq_contract

@pytest.fixture(scope='function')
async def proxy_contract(starknet):
    # Deploy the proxy_contract.
    proxy_contract = await starknet.deploy(PROXY_CONTRACT_FILE)
    yield proxy_contract

@pytest.fixture(scope='function', autouse=True)
async def set_RFQ_ADDRESS_and_PROXY_ADDRESS(rfq_contract, proxy_contract):
    # Set Proxy and RFQ address
    await rfq_contract.set_PROXY_ADDRESS(new_PROXY_ADDRESS=proxy_contract.contract_address).invoke()
    await proxy_contract.set_RFQ_CONTRACT_ADDRESS(new_RFQ_CONTRACT_ADDRESS=rfq_contract.contract_address).invoke()

FEE_BPS = 30
BPS = 10000


@pytest.mark.asyncio
async def test_set_L1_CONTRACT_ADDRESS(rfq_contract):
    # Invoke set_L1_CONTRACT_ADDRESS().
    await rfq_contract.set_L1_CONTRACT_ADDRESS(new_L1_CONTRACT_ADDRESS=123).invoke()

    # Check the result of get_L1_CONTRACT_ADDRESS().
    assert await rfq_contract.get_L1_CONTRACT_ADDRESS().call() == (123,)

@pytest.mark.asyncio
async def test_set_PROXY_ADDRESS(rfq_contract):
    # Invoke set_PROXY_ADDRESS().
    await rfq_contract.set_PROXY_ADDRESS(new_PROXY_ADDRESS=456).invoke()

    # Check the result of get_PROXY_ADDRESS().
    assert await rfq_contract.get_PROXY_ADDRESS().call() == (456,)

@pytest.mark.asyncio
async def test_set_RFQ_ADDRESS(proxy_contract):
    # Invoke set_RFQ_CONTRACT_ADDRESS().
    await proxy_contract.set_RFQ_CONTRACT_ADDRESS(new_RFQ_CONTRACT_ADDRESS=456).invoke()

    # Check the result of get_RFQ_CONTRACT_ADDRESS().
    assert await proxy_contract.get_RFQ_CONTRACT_ADDRESS().call() == (456,)

@pytest.mark.asyncio
async def test_modify_user_balance(rfq_contract, proxy_contract):
    # Invoke call_modify_user_balance().
    await proxy_contract.call_modify_user_balance(public_key=111, token_id=0, amount=1000).invoke()

    # Check the result of get_balance().
    assert await rfq_contract.get_balance(user=111, token_id=0).call() == (1000,)

@pytest.mark.asyncio
async def test_modify_user_balance_call_by_user(rfq_contract):
    with pytest.raises(StarkException) as e:
        await rfq_contract.modify_user_balance(public_key=111, token_id=0, amount=1000).invoke()

@pytest.mark.asyncio
async def test_withdraw(rfq_contract, proxy_contract):
    user = 798472886190004179001673494155360729135078329522332065779728082154055368978
    priv_key = 654321
    token_id = 0
    amount = 9000

    # Modify user balance
    await proxy_contract.call_modify_user_balance(public_key=user, token_id=token_id, amount=amount).invoke()
    assert await rfq_contract.get_balance(user=user, token_id=token_id).call() == (amount,)

    withdrawal_hash = pedersen_hash(int(token_id), int(amount))
    r, s = sign(
        msg_hash=withdrawal_hash,
        priv_key=priv_key)
    await rfq_contract.withdraw(user=user, token_id=token_id, amount=amount, sig_r=r, sig_s=s).invoke()
    assert await rfq_contract.get_balance(user=user, token_id=token_id).call() == (0,)

@pytest.mark.asyncio
async def test_fill_order(rfq_contract, proxy_contract):
    taker = 798472886190004179001673494155360729135078329522332065779728082154055368978
    taker_priv_key = 654321
    taker_token_id = 0
    taker_amount = 9000
    maker = 965622539618741639684405678770953753815496707531483492053037473521675738736
    maker_priv_key = 777777
    maker_token_id = 1
    maker_amount = 3000
    salt = 999

    # Modify taker balance
    await proxy_contract.call_modify_user_balance(public_key=taker, token_id=taker_token_id, amount=taker_amount).invoke()
    assert await rfq_contract.get_balance(user=taker, token_id=taker_token_id).call() == (taker_amount,)
    # Modify maker balance
    await proxy_contract.call_modify_user_balance(public_key=maker, token_id=maker_token_id, amount=maker_amount).invoke()
    assert await rfq_contract.get_balance(user=maker, token_id=maker_token_id).call() == (maker_amount,)

    order_hash = compute_tx_hash(
        taker,
        taker_token_id,
        taker_amount,
        maker,
        maker_token_id,
        maker_amount,
        salt)
    # Taker signs
    taker_r, taker_s = sign(
        msg_hash=order_hash,
        priv_key=taker_priv_key)
    # Maker signs
    maker_r, maker_s = sign(
        msg_hash=order_hash,
        priv_key=maker_priv_key)
    # Fill order
    await rfq_contract.fill_order(
        taker_public_key=taker,
        taker_token_id=taker_token_id,
        taker_token_amount=taker_amount,
        r_a=taker_r,
        s_a=taker_s,
        maker_public_key=maker,
        maker_token_id=maker_token_id,
        maker_token_amount=maker_amount,
        r_b=maker_r,
        s_b=maker_s,
        salt=salt).invoke()

    # Check taker and maker balances
    maker_amount_sub_fee = int(maker_amount * (BPS - FEE_BPS) / BPS)
    assert await rfq_contract.get_balance(user=taker, token_id=taker_token_id).call() == (0,)
    assert await rfq_contract.get_balance(user=maker, token_id=maker_token_id).call() == (0,)
    assert await rfq_contract.get_balance(user=taker, token_id=maker_token_id).call() == (maker_amount_sub_fee,)
    assert await rfq_contract.get_balance(user=maker, token_id=taker_token_id).call() == (taker_amount,)
