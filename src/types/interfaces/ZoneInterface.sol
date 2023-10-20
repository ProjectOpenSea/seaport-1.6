// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ZoneParameters, Schema } from "../lib/ConsiderationStructs.sol";

import { IERC165 } from "./IERC165.sol";

/**
 * @title  ZoneInterface
 * @notice Contains functions exposed by a zone.
 */
interface ZoneInterface is IERC165 {
    /**
     * @dev Authorizes an order before any token fulfillments from any order have been executed by Seaport.
     *
     * @param zoneParameters The context about the order fulfillment and any
     *                       supplied extraData.
     *
     * @return authorizedOrderMagicValue The magic value that indicates a valid
     *                              order.
     */
    function authorizeOrder(ZoneParameters calldata zoneParameters)
        external
        returns (bytes4 authorizedOrderMagicValue);

    /**
     * @dev Validates an order after all token fulfillments for all orders have been executed by Seaport.
     *
     * @param zoneParameters The context about the order fulfillment and any
     *                       supplied extraData.
     *
     * @return validOrderMagicValue The magic value that indicates a valid
     *                              order.
     */
    function validateOrder(ZoneParameters calldata zoneParameters)
        external
        returns (bytes4 validOrderMagicValue);

    /**
     * @dev Returns the metadata for this zone.
     *
     * @return name The name of the zone.
     * @return schemas The schemas that the zone implements.
     */
    function getSeaportMetadata()
        external
        view
        returns (string memory name, Schema[] memory schemas); // map to Seaport Improvement Proposal IDs

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool);
}
