// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script, console2 } from "forge-std/Script.sol";
import { ConduitController } from
    "seaport-core/src/conduit/ConduitController.sol";
import { Consideration } from "seaport-core/src/lib/Consideration.sol";

contract TstorishDeploy is Script {
    function run() public {
        vm.broadcast();
        ConduitController controller = new ConduitController();
        vm.label(address(controller), "controller");
        vm.broadcast();
        Consideration seaport = new Consideration(address(controller));
    }
}
