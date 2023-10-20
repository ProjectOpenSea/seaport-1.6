// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SeaportRouter as CoreSeaportRouter } from
    "seaport-core/src/helpers/SeaportRouter.sol";

contract SeaportRouter is CoreSeaportRouter {
    /// @dev The allowed v1.4 contract usable through this router.
    address private immutable _SEAPORT_V1_4;
    /// @dev The allowed v1.5 contract usable through this router.
    address private immutable _SEAPORT_V1_5;

    constructor(address seaportV1point4, address seaportV1point5)
        CoreSeaportRouter(seaportV1point4, seaportV1point5)
    {
        _SEAPORT_V1_4 = seaportV1point4;
        _SEAPORT_V1_5 = seaportV1point5;
    }
}
