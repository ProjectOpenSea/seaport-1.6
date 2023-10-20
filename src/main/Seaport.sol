// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Consideration as CoreConsideration } from
    "seaport-core/src/lib/Consideration.sol";

contract Seaport is CoreConsideration {
    constructor(address conduitController)
        CoreConsideration(conduitController)
    { }
}
