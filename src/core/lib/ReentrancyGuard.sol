// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    ReentrancyErrors
} from "seaport-types/src/interfaces/ReentrancyErrors.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import {
    _revertInvalidMsgValue,
    _revertNoReentrantCalls
} from "seaport-types/src/lib/ConsiderationErrors.sol";

import {
    _ENTERED_AND_ACCEPTING_NATIVE_TOKENS_SSTORE,
    _ENTERED_SSTORE,
    _NOT_ENTERED_SSTORE,
    _ENTERED_AND_ACCEPTING_NATIVE_TOKENS_TSTORE,
    _ENTERED_TSTORE,
    _NOT_ENTERED_TSTORE,
    _TSTORE_ENABLED_SSTORE,
    _REENTRANCY_GUARD_SLOT,
    _TLOAD_TEST_PAYLOAD,
    _TLOAD_TEST_PAYLOAD_OFFSET,
    _TLOAD_TEST_PAYLOAD_LENGTH
} from "seaport-types/src/lib/ConsiderationConstants.sol";

import {
    InvalidMsgValue_error_selector,
    InvalidMsgValue_error_length,
    InvalidMsgValue_error_value_ptr,
    NoReentrantCalls_error_selector,
    NoReentrantCalls_error_length,
    Error_selector_offset
} from "seaport-types/src/lib/ConsiderationErrorConstants.sol";

/**
 * @title ReentrancyGuard
 * @author 0age
 * @notice ReentrancyGuard contains a storage variable (or a transient storage
 *         variable in EVM environments that support it once activated) and
 *         related functionality for protecting against reentrancy.
 */
contract ReentrancyGuard is ReentrancyErrors, LowLevelHelpers {
    // Declare an immutable variable to store the initial TSTORE support status.
    bool private immutable _tstoreInitialSupport;

    // Declare an immutable variable to store the tstore test contract address.
    address private immutable _tloadTestContract;

    /**
     * @dev Initialize the reentrancy guard during deployment. This involves
     *      attempting to deploy a contract that utilizes TLOAD as part of the
     *      contract construction bytecode, and configuring initial support for
     *      using TSTORE in place of SSTORE for the reentrancy lock based on the
     *      result.
     */
    constructor() {
        // Deploy the contract testing TLOAD support and store the address.
        address tloadTestContract = _prepareTloadTest();

        // Ensure the deployment was successful.
        if (tloadTestContract == address(0)) {
            revert TloadTestContractDeploymentFailed();
        }

        // Determine if TSTORE is supported.
        bool tstoreInitialSupport = _testTload(tloadTestContract);

        // Store the result as an immutable.
        _tstoreInitialSupport = tstoreInitialSupport;

        // Set the address of the deployed TLOAD test contract as an immutable.
        _tloadTestContract = tloadTestContract;

        // If not using TSTORE (where _NOT_ENTERED_TSTORE = 0), set initial
        // sentinel value (where _NOT_ENTERED_SSTORE = 1).
        if (!tstoreInitialSupport) {
            // Initialize storage for the reentrancy guard in a cleared state.
            assembly {
                sstore(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED_SSTORE)
            }
        }
    }

    /**
     * @dev External function to activate TSTORE usage for the reentrancy guard.
     *      Does not need to be called if TSTORE is supported from deployment,
     *      and only needs to be called once. Reverts if TSTORE has already been
     *      activated, if the opcode is not available, or if the reentrancy
     *      guard is currently set.
     */
    function __activateTstore() external {
        // Determine if TSTORE can potentially be activated. If it has already
        // been activated, or if the reentrancy guard is currently set, then
        // it cannot be activated.
        bool tstoreActivatable;
        assembly {
            tstoreActivatable := eq(
                sload(_REENTRANCY_GUARD_SLOT),
                _NOT_ENTERED_SSTORE
            )
        }

        // Revert if TSTORE is already activated or not activatable.
        if (_tstoreInitialSupport || !tstoreActivatable) {
            revert TStoreAlreadyActivated();
        }

        // Determine if TSTORE can be activated and revert if not.
        if (!_testTload(_tloadTestContract)) {
            revert TStoreNotSupported();
        }

        // Mark TSTORE as activated.
        assembly {
            sstore(_REENTRANCY_GUARD_SLOT, _TSTORE_ENABLED_SSTORE)
        }
    }

    /**
     * @dev Internal function to ensure that a sentinel value for the reentrancy
     *      guard is not currently set and, if not, to set a sentinel value for
     *      the reentrancy guard based on whether or not native tokens may be
     *      received during execution or not.
     *
     * @param acceptNativeTokens A boolean indicating whether native tokens may
     *                           be received during execution or not.
     */
    function _setReentrancyGuard(bool acceptNativeTokens) internal {
        // Place immutable variable on the stack access within inline assembly.
        bool tstoreInitialSupport = _tstoreInitialSupport;

        // Utilize assembly to set the reentrancy guard based on tstore support.
        assembly {
            // "Loop" over three possible cases for setting the reentrancy guard
            // based on tstore support and state, exiting once the respective
            // state has been identified and a corresponding guard has been set.
            for {

            } 1 {

            } {
                // 1: handle case where tstore is supported from the start.
                if tstoreInitialSupport {
                    // Ensure that the reentrancy guard is not already set.
                    if tload(_REENTRANCY_GUARD_SLOT) {
                        // Store left-padded selector with push4,
                        // mem[28:32] = selector
                        mstore(0, NoReentrantCalls_error_selector)

                        // revert(abi.encodeWithSignature("NoReentrantCalls()"))
                        revert(
                            Error_selector_offset,
                            NoReentrantCalls_error_length
                        )
                    }

                    // Set the reentrancy guard. A value of 1 indicates that
                    // native tokens may not be accepted during execution,
                    // whereas a value of 2 indicates that they will be accepted
                    // (returning any remaining native tokens to the caller).
                    tstore(
                        _REENTRANCY_GUARD_SLOT,
                        add(_ENTERED_TSTORE, acceptNativeTokens)
                    )

                    // Exit the loop.
                    break
                }

                // Retrieve the reentrancy guard sentinel value.
                let reentrancyGuard := sload(_REENTRANCY_GUARD_SLOT)

                // 2: handle tstore support that was activated post-deployment.
                if iszero(reentrancyGuard) {
                    // Ensure that the reentrancy guard is not already set.
                    if tload(_REENTRANCY_GUARD_SLOT) {
                        // Store left-padded selector with push4,
                        // mem[28:32] = selector
                        mstore(0, NoReentrantCalls_error_selector)

                        // revert(abi.encodeWithSignature("NoReentrantCalls()"))
                        revert(
                            Error_selector_offset,
                            NoReentrantCalls_error_length
                        )
                    }

                    // Set the reentrancy guard. A value of 1 indicates that
                    // native tokens may not be accepted during execution,
                    // whereas a value of 2 indicates that they will be accepted
                    // (returning any remaining native tokens to the caller).
                    tstore(
                        _REENTRANCY_GUARD_SLOT,
                        add(_ENTERED_TSTORE, acceptNativeTokens)
                    )

                    // Exit the loop.
                    break
                }

                // 3: handle case where tstore support has not been activated.
                // Ensure that the reentrancy guard is not already set.
                if iszero(eq(reentrancyGuard, _NOT_ENTERED_SSTORE)) {
                    // Store left-padded selector with push4 (reduces bytecode),
                    // mem[28:32] = selector
                    mstore(0, NoReentrantCalls_error_selector)

                    // revert(abi.encodeWithSignature("NoReentrantCalls()"))
                    revert(Error_selector_offset, NoReentrantCalls_error_length)
                }

                // Set the reentrancy guard. A value of 2 indicates that native
                // tokens may not be accepted during execution, whereas a value
                // of 3 indicates that they will be accepted (with any remaining
                // native tokens returned to the caller).
                sstore(
                    _REENTRANCY_GUARD_SLOT,
                    add(_ENTERED_SSTORE, acceptNativeTokens)
                )

                // Exit the loop.
                break
            }
        }
    }

    /**
     * @dev Internal function to unset the reentrancy guard sentinel value.
     */
    function _clearReentrancyGuard() internal {
        // Place immutable variable on the stack access within inline assembly.
        bool tstoreInitialSupport = _tstoreInitialSupport;

        // Utilize assembly to clear reentrancy guard based on tstore support.
        assembly {
            // "Loop" over three possible cases for clearing reentrancy guard
            // based on tstore support and state, exiting once the respective
            // state has been identified and corresponding guard cleared.
            for {

            } 1 {

            } {
                // 1: handle case where tstore is supported from the start.
                if tstoreInitialSupport {
                    // Clear the reentrancy guard.
                    tstore(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED_TSTORE)

                    // Exit the loop.
                    break
                }

                // Retrieve the reentrancy guard sentinel value.
                let reentrancyGuard := sload(_REENTRANCY_GUARD_SLOT)

                // 2: handle tstore support that was activated post-deployment.
                if iszero(reentrancyGuard) {
                    // Clear the reentrancy guard.
                    tstore(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED_TSTORE)

                    // Exit the loop.
                    break
                }

                // 3: handle case where tstore support has not been activated.
                // Clear the reentrancy guard.
                sstore(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED_SSTORE)

                // Exit the loop.
                break
            }
        }
    }

    /**
     * @dev Internal view function to ensure that a sentinel value for the
     *      reentrancy guard is not currently set.
     */
    function _assertNonReentrant() internal view {
        // Place immutable variable on the stack access within inline assembly.
        bool tstoreInitialSupport = _tstoreInitialSupport;

        // Utilize assembly to check reentrancy guard based on tstore support.
        assembly {
            // 1: handle case where tstore is supported from the start.
            if tstoreInitialSupport {
                // Ensure that the reentrancy guard is not currently set.
                if tload(_REENTRANCY_GUARD_SLOT) {
                    // Store left-padded selector with push4,
                    // mem[28:32] = selector
                    mstore(0, NoReentrantCalls_error_selector)

                    // revert(abi.encodeWithSignature("NoReentrantCalls()"))
                    revert(
                        Error_selector_offset,
                        NoReentrantCalls_error_length
                    )
                }
            }

            // Handle cases where tstore is not initially supported.
            if iszero(tstoreInitialSupport) {
                // Retrieve the reentrancy guard sentinel value.
                let reentrancyGuard := sload(_REENTRANCY_GUARD_SLOT)

                // 2: handle tstore support that was activated post-deployment.
                if iszero(reentrancyGuard) {
                    // Ensure that the reentrancy guard is not currently set.
                    if tload(_REENTRANCY_GUARD_SLOT) {
                        // Store left-padded selector with push4,
                        // mem[28:32] = selector
                        mstore(0, NoReentrantCalls_error_selector)

                        // revert(abi.encodeWithSignature("NoReentrantCalls()"))
                        revert(
                            Error_selector_offset,
                            NoReentrantCalls_error_length
                        )
                    }
                }

                // 3: handle case where tstore support has not been activated.
                // Ensure that the reentrancy guard is not currently set.
                if gt(reentrancyGuard, _NOT_ENTERED_SSTORE) {
                    // Store left-padded selector with push4 (reduces bytecode),
                    // mem[28:32] = selector
                    mstore(0, NoReentrantCalls_error_selector)

                    // revert(abi.encodeWithSignature("NoReentrantCalls()"))
                    revert(Error_selector_offset, NoReentrantCalls_error_length)
                }
            }
        }
    }

    /**
     * @dev Internal view function to ensure that the sentinel value indicating
     *      native tokens may be received during execution is currently set.
     */
    function _assertAcceptingNativeTokens() internal view {
        // Place immutable variable on the stack access within inline assembly.
        bool tstoreInitialSupport = _tstoreInitialSupport;

        // Utilize assembly to check reentrancy guard based on tstore support.
        assembly {
            // 1: handle case where tstore is supported from the start.
            if tstoreInitialSupport {
                // Ensure reentrancy guard is set to accept native tokens.
                if iszero(
                    eq(
                        tload(_REENTRANCY_GUARD_SLOT),
                        _ENTERED_AND_ACCEPTING_NATIVE_TOKENS_TSTORE
                    )
                ) {
                    // Store left-padded selector with push4,
                    // mem[28:32] = selector
                    mstore(0, InvalidMsgValue_error_selector)

                    // Store argument.
                    mstore(InvalidMsgValue_error_value_ptr, callvalue())

                    // revert(abi.encodeWithSignature(
                    //   "InvalidMsgValue(uint256)", value)
                    // )
                    revert(
                        Error_selector_offset,
                        InvalidMsgValue_error_length
                    )
                }
            }

            // Handle cases where tstore is not initially supported.
            if iszero(tstoreInitialSupport) {
                // Retrieve the reentrancy guard sentinel value.
                let reentrancyGuard := sload(_REENTRANCY_GUARD_SLOT)

                // 2: handle tstore support that was activated post-deployment.
                if iszero(reentrancyGuard) {
                    // Ensure reentrancy guard is set to accept native tokens.
                    if iszero(
                        eq(
                            tload(_REENTRANCY_GUARD_SLOT),
                            _ENTERED_AND_ACCEPTING_NATIVE_TOKENS_TSTORE
                        )
                    ) {
                        // Store left-padded selector with push4,
                        // mem[28:32] = selector
                        mstore(0, InvalidMsgValue_error_selector)

                        // Store argument.
                        mstore(InvalidMsgValue_error_value_ptr, callvalue())

                        // revert(abi.encodeWithSignature(
                        //   "InvalidMsgValue(uint256)", value)
                        // )
                        revert(
                            Error_selector_offset,
                            InvalidMsgValue_error_length
                        )
                    }
                }

                // 3: handle case where tstore support has not been activated.
                // Ensure reentrancy guard is set to accepting native tokens.
                if and(
                    iszero(iszero(reentrancyGuard)),
                    iszero(
                        eq(
                            reentrancyGuard,
                            _ENTERED_AND_ACCEPTING_NATIVE_TOKENS_SSTORE
                        )
                    )
                ) {
                    // Store left-padded selector with push4 (reduces bytecode),
                    // mem[28:32] = selector
                    mstore(0, InvalidMsgValue_error_selector)

                    // Store argument.
                    mstore(InvalidMsgValue_error_value_ptr, callvalue())

                    // revert(abi.encodeWithSignature(
                    //   "InvalidMsgValue(uint256)", value)
                    // )
                    revert(Error_selector_offset, InvalidMsgValue_error_length)
                }
            }
        }
    }

    /**
     * @dev Private function to deploy a test contract that utilizes TLOAD as
     *      part of its fallback logic.
     */
    function _prepareTloadTest() private returns (address contractAddress) {
        // Utilize assembly to deploy a contract testing TLOAD support.
        assembly {
            // Write the contract deployment code payload to scratch space.
            mstore(0, _TLOAD_TEST_PAYLOAD)

            // Deploy the contract.
            contractAddress := create(
                0,
                _TLOAD_TEST_PAYLOAD_OFFSET,
                _TLOAD_TEST_PAYLOAD_LENGTH
            )
        }
    }

    /**
     * @dev Private view function to determine if TSTORE/TLOAD are supported by
     *      the current EVM implementation by attempting to call the test
     *      contract, which utilizes TLOAD as part of its fallback logic.
     */
    function _testTload(
        address tloadTestContract
    ) private view returns (bool ok) {
        // Call the test contract, which will perform a TLOAD test. If the call
        // does not revert, then TLOAD/TSTORE is supported. Do not forward all
        // available gas, as all forwarded gas will be consumed on revert.
        (ok, ) = tloadTestContract.staticcall{ gas: gasleft() / 10 }("");
    }
}
