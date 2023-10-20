// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SeaportRouter as CoreSeaportRouter } from
    "seaport-core/src/helpers/SeaportRouter.sol";
/**
 * @title  SeaportRouter
 * @author Ryan Ghods (ralxz.eth), 0age (0age.eth), James Wenzel (emo.eth)
 * @notice A utility contract for fulfilling orders with multiple
 *         Seaport versions. DISCLAIMER: This contract only works when
 *         all consideration items across all listings are native tokens.
 */

contract LocalSeaportRouter is CoreSeaportRouter {
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
