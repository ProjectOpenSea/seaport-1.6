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

contract VerboseAuthZone is ERC165, ZoneInterface {

    bool shouldReturnInvalidMagicValue;
    bool shouldRevert;

    constructor(bool _shouldReturnInvalidMagicValue, bool _shouldRevert) {
        shouldReturnInvalidMagicValue = _shouldReturnInvalidMagicValue;
        shouldRevert = _shouldRevert;
    }

    event AuthorizeOrderAuthorized(
        bytes32 orderHash
    );

    event AuthorizeOrderReverted(
        bytes32 orderHash
    );

    event AuthorizeOrderReturnedInvalidMagicValue(
        bytes32 orderHash
    );

    error EvenIndexOrdersNotAllowed();

    function authorizeOrder(ZoneParameters calldata zoneParameters)
        public
        returns (bytes4)
    {
        console.log("shouldRevert");
        console.log(shouldRevert);

        console.log("shouldReturnInvalidMagicValue");
        console.log(shouldReturnInvalidMagicValue);

        // struct ZoneParameters {
        //     bytes32 orderHash;
        //     address fulfiller;
        //     address offerer;
        //     SpentItem[] offer;
        //     ReceivedItem[] consideration;
        //     bytes extraData;
        //     bytes32[] orderHashes;
        //     uint256 startTime;
        //     uint256 endTime;
        //     bytes32 zoneHash;
        // }

        console.log("zoneParameters.orderHash");
        console.logBytes32(zoneParameters.orderHash);

        console.log("zoneParameters.offerer");
        console.logAddress(zoneParameters.offerer);

        console.log("zoneParameters.offer.length");
        console.log(zoneParameters.offer.length);

        console.log("zoneParameters.consideration.length");
        console.log(zoneParameters.consideration.length);

        console.log("zoneParameters.extraData.length");
        console.logBytes(zoneParameters.extraData);

        // console.log("zoneParameters.orderHashes.length");
        // console.log(zoneParameters.orderHashes.length);

        console.log("zoneParameters.startTime");
        console.log(zoneParameters.startTime);

        console.log("zoneParameters.endTime");
        console.log(zoneParameters.endTime);

        console.log("zoneParameters.zoneHash");
        console.logBytes32(zoneParameters.zoneHash);

        // console.log("zoneParameters");
        // helm.log(zoneParameters);

        // Refuse to authorize orders that are at even indexes.
        if (zoneParameters.orderHashes.length % 2 == 0) {
            console.log("Performed conditional");

            if (shouldReturnInvalidMagicValue) {
                emit AuthorizeOrderReturnedInvalidMagicValue(
                    zoneParameters.orderHash
                );

                // Return the a value that is not the authorizeOrder magic
                // value.
                return bytes4(0x12345678);
            }

            if (shouldRevert) {   
                emit AuthorizeOrderReverted(
                    zoneParameters.orderHash
                );
                revert EvenIndexOrdersNotAllowed();
            }
        } else {
            console.log("Performed conditional landed in else");
        }

        console.log("Emitting authorized order event");

        emit AuthorizeOrderAuthorized(
            zoneParameters.orderHash
        );

        console.log("Returning authorizeOrder magic value");

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
}
