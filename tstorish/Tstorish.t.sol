// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import {
    ReentrancyGuard,
    ReentrancyErrors
} from "seaport-core/src/lib/ReentrancyGuard.sol";

contract TstorishTest is Test {
    ReentrancyGuard seaport;

    function setUp() public {
        seaport = ReentrancyGuard(
            payable(
                // second contract deployed by first anvil pk
                0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
            )
        );
    }

    function test_activate() public {
        vm.etch(
            0xCafac3dD18aC6c6e92c921884f9E4176737C052c,
            hex"3d5c"
        );

        assertEq(
            address(0xCafac3dD18aC6c6e92c921884f9E4176737C052c).codehash,
            keccak256(hex"3d5c")
        );

        // first call updates storage
        vm.record();
        seaport.__activateTstore();
        (bytes32[] memory reads, bytes32[] memory writes) =
            vm.accesses(address(seaport));
        assertEq(writes.length, 1);
        // second call reverts
        vm.expectRevert(ReentrancyErrors.TStoreAlreadyActivated.selector);
        seaport.__activateTstore();
    }
}
