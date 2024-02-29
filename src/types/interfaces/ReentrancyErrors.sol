// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ReentrancyErrors
 * @author 0age
 * @notice ReentrancyErrors contains errors related to reentrancy.
 */
interface ReentrancyErrors {
    /**
     * @dev Revert with an error when a caller attempts to reenter a protected
     *      function.
     */
    error NoReentrantCalls();

    /**
     * @dev Revert with an error when attempting to activate the TSTORE opcode
     *      when it is already active.
     */
    error TStoreAlreadyActivated();

    /**
     * @dev Revert with an error when attempting to activate the TSTORE opcode
     *      in an EVM environment that does not support it.
     */  
    error TStoreNotSupported();

    /**
     * @dev Revert with an error when deployment of the contract for testing
     *      TSTORE support fails.
     */
    error TloadTestContractDeploymentFailed();
}
