// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyErrors } from
    "seaport-types/src/interfaces/ReentrancyErrors.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import {
    _revertInvalidMsgValue,
    _revertNoReentrantCalls
} from "seaport-types/src/lib/ConsiderationErrors.sol";

import {
    _REENTRANCY_GUARD_SLOT,
    _TLOAD_TEST_PAYLOAD,
    _TLOAD_TEST_PAYLOAD_OFFSET,
    _TLOAD_TEST_PAYLOAD_LENGTH,
    _TSTORE_SUPPORTED_SLOT
} from "seaport-types/src/lib/ConsiderationConstants.sol";

import {
    NoReentrantCalls_error_selector,
    NoReentrantCalls_error_length,
    Error_selector_offset
} from "seaport-types/src/lib/ConsiderationErrorConstants.sol";

import {
    _ENTERED_AND_ACCEPTING_NATIVE_TOKENS,
    _ENTERED,
    _NOT_ENTERED
} from "seaport-types/src/lib/ConsiderationConstants.sol";

/**
 * @title ReentrancyGuard
 * @author 0age
 * @notice ReentrancyGuard contains a storage variable and related functionality
 *         for protecting against reentrancy.
 */
contract ReentrancyGuard is ReentrancyErrors, LowLevelHelpers {
    bool private immutable _tstoreInitialSupport;
    bool private _tstoreSupport;

    error TStoreAlreadyActivated();
    error TStoreNotSupported();

    /**
     * @dev Initialize the reentrancy guard during deployment.
     */
    constructor() {
        _tstoreInitialSupport = _testTload();

        // Initialize the reentrancy guard in a cleared state.
        _setTstorish(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED);
    }

    /**
     * @dev External function to activate TSTORE usage for the reentrancy guard.
     */
    function __activateTstore() external {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        // Activate the tstore opcode if available and not already active.
        _activateTstore();
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
            for {} 1 {} {
                // first: handle case where tstore is supported from the start.
                if tstoreInitialSupport {
                    // Ensure that the reentrancy guard is not already set.
                    if iszero(eq(tload(_REENTRANCY_GUARD_SLOT), _NOT_ENTERED)) {
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
                    tstore(_REENTRANCY_GUARD_SLOT, add(_ENTERED, acceptNativeTokens))

                    // Exit the loop.
                    break
                }

                // second: handle tstore support that was activated post-deployment.
                if sload(_TSTORE_SUPPORTED_SLOT) {
                    // Ensure that the reentrancy guard is not already set.
                    if iszero(eq(tload(_REENTRANCY_GUARD_SLOT), _NOT_ENTERED)) {
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
                    tstore(_REENTRANCY_GUARD_SLOT, add(_ENTERED, acceptNativeTokens))

                    // Exit the loop.
                    break
                }

                // third: handle case where tstore support has not been activated.
                // Ensure that the reentrancy guard is not already set.
                if iszero(eq(sload(_REENTRANCY_GUARD_SLOT), _NOT_ENTERED)) {
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
                sstore(_REENTRANCY_GUARD_SLOT, add(_ENTERED, acceptNativeTokens))

                // Exit the loop.
                break
            }
        }
    }

    /**
     * @dev Internal function to unset the reentrancy guard sentinel value.
     */
    function _clearReentrancyGuard() internal {
        // Clear the reentrancy guard.
        _setTstorish(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED);
    }

    /**
     * @dev Internal view function to ensure that a sentinel value for the
     *         reentrancy guard is not currently set.
     */
    function _assertNonReentrant() internal view {
        // Ensure that the reentrancy guard is not currently set.
        if (_getTstorish(_REENTRANCY_GUARD_SLOT) != _NOT_ENTERED) {
            _revertNoReentrantCalls();
        }
    }

    /**
     * @dev Internal view function to ensure that the sentinel value indicating
     *      native tokens may be received during execution is currently set.
     */
    function _assertAcceptingNativeTokens() internal view {
        // Ensure that the reentrancy guard is not currently set.
        if (
            _getTstorish(_REENTRANCY_GUARD_SLOT) != _ENTERED_AND_ACCEPTING_NATIVE_TOKENS
        ) {
            _revertInvalidMsgValue(msg.value);
        }
    }

    function _testTload() private view returns (bool success) {
        assembly {
            mstore(0, _TLOAD_TEST_PAYLOAD)
            success := iszero(iszero(
                create(
                    0,
                    _TLOAD_TEST_PAYLOAD_OFFSET,
                    _TLOAD_TEST_PAYLOAD_LENGTH
                )
            ))
        }
    }

    function _activateTstore() internal {
        bool tstoreSupported;
        assembly {
            tstoreSupported := sload(_TSTORE_SUPPORTED_SLOT)
        }

        if (_tstoreInitialSupport || tstoreSupported) {
            revert TStoreAlreadyActivated();
        }

        if (!_testTload()) {
            revert TStoreNotSupported();
        }

        assembly {
            sstore(_TSTORE_SUPPORTED_SLOT, 1)
        }
    }

    function _setTstorish(uint256 storageSlot, uint256 value) internal {
        if (_tstoreInitialSupport || _tstoreSupport) {
            assembly {
                tstore(storageSlot, value)
            }
        } else {
            assembly {
                sstore(storageSlot, value)
            }
        }
    }

    function _getTstorish(uint256 storageSlot) internal view returns (uint256 value) {
        if (_tstoreInitialSupport || _tstoreSupport) {
            assembly {
                value := tload(storageSlot)
            }
        } else {
            assembly {
                value := sload(storageSlot)
            }
        }
    }
}
