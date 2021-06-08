#!/usr/bin/python3

import pytest


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="module")
def fill_order(FillOrder, accounts):
    state_tree_root = 3513649642851389103528329536082144519835916108258125939543239512794009914299
    program_hash = 0x6c4cf2c0243a767fb52890c415f68a080e1231c852f2e0cb8b78f2bea200a11
    # verifier_address = ""
    account_ids = [0, 0, 5, 5, 8, 8]
    account_token_ids = [99, 133, 99, 133, 99, 133]
    account_token_balances = [1000000, 5000000, 7500000, 200000, 45000, 11100]
    return FillOrder.deploy(
        state_tree_root,
        program_hash,
        # verifier_address,
        account_ids,
        account_token_ids,
        account_token_balances,
        {'from': accounts[0]}
    )