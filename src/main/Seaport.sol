// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Seaport as CoreSeaport } from "seaport-core/src/Seaport.sol";

contract Seaport is CoreSeaport {
    constructor(address conduitController) CoreSeaport(conduitController) { }
}
