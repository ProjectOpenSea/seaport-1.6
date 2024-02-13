// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    Schema,
    ZoneParameters
} from "seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType } from "seaport-types/src/lib/ConsiderationEnums.sol";

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { ZoneInterface } from "seaport-types/src/interfaces/ZoneInterface.sol";

import "forge-std/console.sol";
import { helm } from "seaport-sol/src/helm.sol";
import "forge-std/console2.sol";

contract VerboseAuthZone is ERC165, ZoneInterface {

    // Create a mapping of orderHashes to authorized status.
    mapping (bytes32 => bool) public orderIsAuthorized;

    bool shouldReturnInvalidMagicValue;
    bool shouldRevert;

    event Authorized(
        bytes32 orderHash
    );

    event AuthorizeOrderReverted(
        bytes32 orderHash
    );

    event AuthorizeOrderNonMagicValue(
        bytes32 orderHash
    );

    error OrderNotAuthorized();

    constructor(bool _shouldReturnInvalidMagicValue, bool _shouldRevert) {
        shouldReturnInvalidMagicValue = _shouldReturnInvalidMagicValue;
        shouldRevert = _shouldRevert;
    }

    function authorizeOrder(ZoneParameters calldata zoneParameters)
        public
        returns (bytes4)
    {
        console.log('--------------------------------------------');

        if (!orderIsAuthorized[zoneParameters.orderHash]) {
            if (shouldReturnInvalidMagicValue) {
                console.log("==Returning invalid magic value and emitting");
                emit AuthorizeOrderNonMagicValue(
                    zoneParameters.orderHash
                );

                // Return the a value that is not the authorizeOrder magic
                // value.
                return bytes4(0x12345678);
            }

            if (shouldRevert) {   
                console.log("==Reverting and emitting");
                emit AuthorizeOrderReverted(
                    zoneParameters.orderHash
                );
                revert OrderNotAuthorized();
            }
        }

        console.log("==Blessing and emitting");
        emit Authorized(
            zoneParameters.orderHash
        );

        // Return the authorizeOrder magic value.
        return this.authorizeOrder.selector;
    }

    /**
     * @dev Validates the order with the given `zoneParameters`.  Called by
     *      Consideration whenever any extraData is provided by the caller.
     *
     * @ param zoneParameters The parameters for the order.
     *
     * @ return validOrderMagicValue The validOrder magic value.
     */
    function validateOrder(ZoneParameters calldata /* zoneParameters */)
        external
        pure
        returns (bytes4 validOrderMagicValue)
    {
       
        // Return the validOrderMagicValue.
        return ZoneInterface.validateOrder.selector;
    }

    /**
     * @dev Returns the metadata for this zone.
     */
    function getSeaportMetadata()
        external
        pure
        override
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        )
    {
        schemas = new Schema[](1);
        schemas[0].id = 3003;
        schemas[0].metadata = new bytes(0);

        return ("StatefulTestZone", schemas);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, ZoneInterface)
        returns (bool)
    {
        return interfaceId == type(ZoneInterface).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function setAuthorizationStatus(bytes32 orderHash, bool status) public {
        orderIsAuthorized[orderHash] = status;
    }
}
