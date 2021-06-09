// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact)
        external view
        returns(bool);
}

contract FillOrder is Ownable {

    using SafeMath for uint256;

    // Off-chain state attributes.
    uint256 stateTreeRoot_;

    // The Cairo program hash.
    uint256 cairoProgramHash_;

    // The Cairo verifier.
    IFactRegistry cairoVerifier_;

    // On-chain fee balances.
    mapping(uint256 => uint256) feesCollected_;

    struct Account {
        bytes32 publicKey;
        // TODO: move balances off-chain and use merkle proof of balance to withdraw
        mapping(uint256 => uint256) tokenBalances;
    }
    mapping(bytes32 => uint256) accountId_;
    mapping(uint256 => Account) accounts_;

    uint8 constant TransactionSize = 8;
    struct Transaction {
        uint256 takerAccountId;
        uint256 takerTokenId;
        uint256 takerTokenAmount;
        uint256 makerAccountId;
        uint256 makerTokenId;
        uint256 makerTokenAmount;
        uint256 salt;
        uint256 feeAmount;
    }

    /* ========== EVENTS ========== */

    event UpdateState(bytes32 fact, uint256 newStateRoot);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 stateTreeRoot,
        uint256 cairoProgramHash,
        // address cairoVerifier,
        uint256[] memory accountIds,
        bytes32[] memory accountPublickeys,
        uint256[] memory accountTokenIds,
        uint256[] memory accountTokenBalances)
        public
    {
        stateTreeRoot_ = stateTreeRoot;
        cairoProgramHash_ = cairoProgramHash;
        // cairoVerifier_ = IFactRegistry(cairoVerifier);

        // Initialize the state
        for (uint256 i = 0 ; i < accountIds.length; i++) {
            if (accounts_[accountIds[i]].publicKey == bytes32(0)) {
                accounts_[accountIds[i]].publicKey = accountPublickeys[i];
                accountId_[accountPublickeys[i]] = accountIds[i];
            }
            accounts_[accountIds[i]].tokenBalances[accountTokenIds[i]] = accountTokenBalances[i];
        }
    }

    /* ========== VIEWS ========== */

    function cairoVerifier() external view returns (address) {
        return address(cairoVerifier_);
    }

    function stateTreeRoot() external view returns (uint256) {
        return stateTreeRoot_;
    }

    function cairoProgramHash() external view returns (uint256) {
        return cairoProgramHash_;
    }

    function getAccountId(bytes32 publicKey) external view returns (uint256) {
        return accountId_[publicKey];
    }

    function getAccountPublickey(uint256 accountId) external view returns (bytes32) {
        return accounts_[accountId].publicKey;
    }

    // function tokenBalance(address _accountAddress, uint256 tokenId) external view returns (uint256) {
    //     uint256 _accountId = accountId_[_accountAddress];
    //     return tokenBalances_[_accountId][tokenId];
    // }

    function getTokenBalance(uint256 accountId, uint256 tokenId) external view returns (uint256) {
        return accounts_[accountId].tokenBalances[tokenId];
    }

    function getCollectedFeeBalance(uint256 tokenId) external view returns (uint256) {
        return feesCollected_[tokenId];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ========== RESTRICTED FUNCTIONS ========== */

    function updateState(
        Transaction[] calldata transactions,
        uint256 newStateRoot
    )
        external onlyOwner
    {
        uint256 programOutputLength = transactions.length * TransactionSize + 2;
        uint256[] memory programOutput = new uint256[](programOutputLength);
        for (uint256 i = 0 ; i < transactions.length; i++) {
            programOutput[TransactionSize * i + 0] = transactions[i].takerAccountId;
            programOutput[TransactionSize * i + 1] = transactions[i].takerTokenId;
            programOutput[TransactionSize * i + 2] = transactions[i].takerTokenAmount;
            programOutput[TransactionSize * i + 3] = transactions[i].makerAccountId;
            programOutput[TransactionSize * i + 4] = transactions[i].makerTokenId;
            programOutput[TransactionSize * i + 5] = transactions[i].makerTokenAmount;
            programOutput[TransactionSize * i + 6] = transactions[i].salt;
            programOutput[TransactionSize * i + 7] = transactions[i].feeAmount;
        }
        programOutput[transactions.length * TransactionSize] = stateTreeRoot_;
        programOutput[transactions.length * TransactionSize + 1] = newStateRoot;
        // Ensure that a corresponding proof was verified.
        bytes32 outputHash = keccak256(abi.encodePacked(programOutput));
        bytes32 fact = keccak256(abi.encodePacked(cairoProgramHash_, outputHash));
        // require(cairoVerifier_.isValid(fact), "MISSING_CAIRO_PROOF");

        // Process transactions
        for (uint256 i = 0 ; i < transactions.length; i++) {
            uint256 takerAccountId = transactions[i].takerAccountId;
            uint256 takerTokenId = transactions[i].takerTokenId;
            uint256 takerTokenAmount = transactions[i].takerTokenAmount;
            uint256 makerAccountId = transactions[i].makerAccountId;
            uint256 makerTokenId = transactions[i].makerTokenId;
            uint256 makerTokenAmount = transactions[i].makerTokenAmount;
            uint256 feeAmount = transactions[i].feeAmount;
            accounts_[takerAccountId].tokenBalances[takerTokenId] = accounts_[takerAccountId].tokenBalances[takerTokenId].sub(takerTokenAmount);
            accounts_[takerAccountId].tokenBalances[makerTokenId] = accounts_[takerAccountId].tokenBalances[makerTokenId].add(makerTokenAmount.sub(feeAmount));
            accounts_[makerAccountId].tokenBalances[makerTokenId] = accounts_[makerAccountId].tokenBalances[makerTokenId].sub(makerTokenAmount);
            accounts_[makerAccountId].tokenBalances[takerTokenId] = accounts_[makerAccountId].tokenBalances[takerTokenId].add(takerTokenAmount);
            feesCollected_[makerTokenId] = feesCollected_[makerTokenId].add(feeAmount);
        }

        // Update state root
        stateTreeRoot_ = newStateRoot;

        emit UpdateState(fact, newStateRoot);
    }

}
