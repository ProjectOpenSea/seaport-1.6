// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

interface SeaportReentrancyGuard {
    function __activateTstore() external;

    error TStoreNotSupported();
}

contract TstorishLegacyTest is Test {
    SeaportReentrancyGuard seaport;

    function setUp() public {
        seaport = SeaportReentrancyGuard(
            // second contract deployed by first anvil pk
            0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        );
    }

    function test_preActivate() public {
        assertEq(
            address(0xCafac3dD18aC6c6e92c921884f9E4176737C052c).codehash,
            keccak256(hex"3d5c")
        );

        vm.expectRevert(SeaportReentrancyGuard.TStoreNotSupported.selector);
        seaport.__activateTstore();  
    }
}
