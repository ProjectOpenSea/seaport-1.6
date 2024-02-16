// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ItemType,
    Side,
    OrderType
} from "seaport-types/src/lib/ConsiderationEnums.sol";

import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    OfferItem,
    Order,
    OrderComponents,
    OrderParameters,
    SpentItem,
    ReceivedItem,
    ZoneParameters,
    CriteriaResolver
} from "seaport-types/src/lib/ConsiderationStructs.sol";

import { SeaportInterface } from "../SeaportInterface.sol";

import { GettersAndDerivers } from "seaport-core/src/lib/GettersAndDerivers.sol";

import { UnavailableReason } from "../SpaceEnums.sol";

import { AdvancedOrderLib } from "./AdvancedOrderLib.sol";

import { ConsiderationItemLib } from "./ConsiderationItemLib.sol";

import { OfferItemLib } from "./OfferItemLib.sol";

import { ReceivedItemLib } from "./ReceivedItemLib.sol";

import { OrderParametersLib } from "./OrderParametersLib.sol";

import { StructCopier } from "./StructCopier.sol";

import { AmountDeriverHelper } from "./fulfillment/AmountDeriverHelper.sol";

import { OrderDetails } from "../fulfillments/lib/Structs.sol";

import "forge-std/console.sol";

interface FailingContractOfferer {
    function failureReasons(bytes32) external view returns (uint256);
}

interface RejectingZone {
    function authorizeFailureReasons(bytes32) external view returns (uint256);
}

library ZoneParametersLib {
    using AdvancedOrderLib for AdvancedOrder;
    using AdvancedOrderLib for AdvancedOrder[];
    using OfferItemLib for OfferItem;
    using OfferItemLib for OfferItem[];
    using ConsiderationItemLib for ConsiderationItem;
    using ConsiderationItemLib for ConsiderationItem[];
    using OrderParametersLib for OrderParameters;

    struct ZoneParametersStruct {
        AdvancedOrder[] advancedOrders;
        address fulfiller;
        uint256 maximumFulfilled;
        address seaport;
        CriteriaResolver[] criteriaResolvers;
    }

    struct ZoneDetails {
        AdvancedOrder[] advancedOrders;
        address fulfiller;
        uint256 maximumFulfilled;
        OrderDetails[] orderDetails;
        bytes32[] orderHashes;
    }

    function getZoneAuthorizeParameters(
        AdvancedOrder memory advancedOrder,
        address fulfiller,
        uint256 counter,
        address seaport,
        CriteriaResolver[] memory criteriaResolvers
    ) internal view returns (ZoneParameters memory zoneParameters) {
        SeaportInterface seaportInterface = SeaportInterface(seaport);
        // Get orderParameters from advancedOrder
        OrderParameters memory orderParameters = advancedOrder.parameters;

        // Get orderHash
        bytes32 orderHash =
            advancedOrder.getTipNeutralizedOrderHash(seaportInterface, counter);

        (SpentItem[] memory spentItems, ReceivedItem[] memory receivedItems) =
        orderParameters.getSpentAndReceivedItems(
            advancedOrder.numerator,
            advancedOrder.denominator,
            0,
            criteriaResolvers
        );

        // Create ZoneParameters and add to zoneParameters array
        zoneParameters = ZoneParameters({
            orderHash: orderHash,
            fulfiller: fulfiller,
            offerer: orderParameters.offerer,
            offer: spentItems,
            consideration: receivedItems,
            extraData: advancedOrder.extraData,
            orderHashes: new bytes32[](0),
            startTime: orderParameters.startTime,
            endTime: orderParameters.endTime,
            zoneHash: orderParameters.zoneHash
        });
    }

    function getZoneAuthorizeParameters(
        AdvancedOrder[] memory advancedOrders,
        address fulfiller,
        uint256 maximumFulfilled,
        address seaport,
        CriteriaResolver[] memory criteriaResolvers,
        UnavailableReason[] memory unavailableReasons
    ) internal view returns (ZoneParameters[] memory) {
        return _getZoneParametersFromStruct(
            _getZoneParametersStruct(
                advancedOrders,
                fulfiller,
                maximumFulfilled,
                seaport,
                criteriaResolvers
            ),
            unavailableReasons,
            true
        );
    }

    function getZoneValidateParameters(
        AdvancedOrder memory advancedOrder,
        address fulfiller,
        uint256 counter,
        address seaport,
        CriteriaResolver[] memory criteriaResolvers
    ) internal view returns (ZoneParameters memory zoneParameters) {
        SeaportInterface seaportInterface = SeaportInterface(seaport);
        // Get orderParameters from advancedOrder
        OrderParameters memory orderParameters = advancedOrder.parameters;

        // Get orderHash
        bytes32 orderHash =
            advancedOrder.getTipNeutralizedOrderHash(seaportInterface, counter);

        (SpentItem[] memory spentItems, ReceivedItem[] memory receivedItems) =
        orderParameters.getSpentAndReceivedItems(
            advancedOrder.numerator,
            advancedOrder.denominator,
            0,
            criteriaResolvers
        );

        // Store orderHash in orderHashes array to pass into zoneParameters
        bytes32[] memory orderHashes = new bytes32[](1);
        orderHashes[0] = orderHash;

        // Create ZoneParameters and add to zoneParameters array
        zoneParameters = ZoneParameters({
            orderHash: orderHash,
            fulfiller: fulfiller,
            offerer: orderParameters.offerer,
            offer: spentItems,
            consideration: receivedItems,
            extraData: advancedOrder.extraData,
            orderHashes: new bytes32[](0),
            startTime: orderParameters.startTime,
            endTime: orderParameters.endTime,
            zoneHash: orderParameters.zoneHash
        });
    }

    function getZoneValidateParameters(
        AdvancedOrder[] memory advancedOrders,
        address fulfiller,
        uint256 maximumFulfilled,
        address seaport,
        CriteriaResolver[] memory criteriaResolvers,
        UnavailableReason[] memory unavailableReasons
    ) internal view returns (ZoneParameters[] memory) {
        return _getZoneParametersFromStruct(
            _getZoneParametersStruct(
                advancedOrders,
                fulfiller,
                maximumFulfilled,
                seaport,
                criteriaResolvers
            ),
            unavailableReasons,
            false
        );
    }

    function _getZoneParametersStruct(
        AdvancedOrder[] memory advancedOrders,
        address fulfiller,
        uint256 maximumFulfilled,
        address seaport,
        CriteriaResolver[] memory criteriaResolvers
    ) internal pure returns (ZoneParametersStruct memory) {
        return ZoneParametersStruct(
            advancedOrders,
            fulfiller,
            maximumFulfilled,
            seaport,
            criteriaResolvers
        );
    }

    function _getZoneParametersFromStruct(
        ZoneParametersStruct memory zoneParametersStruct,
        UnavailableReason[] memory unavailableReasons,
        bool isAuthorize
    ) internal view returns (ZoneParameters[] memory) {
        // TODO: use testHelpers pattern to use single amount deriver helper
        ZoneDetails memory details = _getZoneDetails(zoneParametersStruct);

        // Convert offer + consideration to spent + received
        _applyOrderDetails(details, zoneParametersStruct, unavailableReasons);

        // Iterate over advanced orders to calculate orderHashes
        _applyOrderHashes(details, zoneParametersStruct.seaport);

        return _finalizeZoneParameters(details, isAuthorize);
    }

    function _getZoneDetails(ZoneParametersStruct memory zoneParametersStruct)
        internal
        pure
        returns (ZoneDetails memory)
    {
        return ZoneDetails({
            advancedOrders: zoneParametersStruct.advancedOrders,
            fulfiller: zoneParametersStruct.fulfiller,
            maximumFulfilled: zoneParametersStruct.maximumFulfilled,
            orderDetails: new OrderDetails[]( zoneParametersStruct.advancedOrders.length),
            orderHashes: new bytes32[]( zoneParametersStruct.advancedOrders.length)
        });
    }

    function _applyOrderDetails(
        ZoneDetails memory details,
        ZoneParametersStruct memory zoneParametersStruct,
        UnavailableReason[] memory unavailableReasons
    ) internal view {
        bytes32[] memory orderHashes =
            details.advancedOrders.getOrderHashes(zoneParametersStruct.seaport);

        details.orderDetails = zoneParametersStruct
            .advancedOrders
            .getOrderDetails(
            zoneParametersStruct.criteriaResolvers,
            orderHashes,
            unavailableReasons
        );
    }

    function _applyOrderHashes(ZoneDetails memory details, address seaport)
        internal
        view
    {
        bytes32[] memory orderHashes =
            details.advancedOrders.getOrderHashes(seaport);

        uint256 totalFulfilled = 0;
        // Iterate over advanced orders to calculate orderHashes
        for (uint256 i = 0; i < details.advancedOrders.length; i++) {
            bytes32 orderHash = orderHashes[i];

            if (
                totalFulfilled >= details.maximumFulfilled
                    || _isUnavailable(
                        details.advancedOrders[i].parameters,
                        orderHash,
                        SeaportInterface(seaport)
                    )
            ) {
                // Set orderHash to 0 if order index exceeds maximumFulfilled
                details.orderHashes[i] = bytes32(0);
            } else {
                // Add orderHash to orderHashes and increment totalFulfilled
                details.orderHashes[i] = orderHash;
                ++totalFulfilled;
            }
        }
    }

    function _isUnavailable(
        OrderParameters memory order,
        bytes32 orderHash,
        SeaportInterface seaport
    ) internal view returns (bool) {
        (, bool isCancelled, uint256 totalFilled, uint256 totalSize) =
            seaport.getOrderStatus(orderHash);

        bool isRevertingContractOrder = false;
        if (order.orderType == OrderType.CONTRACT) {
            isRevertingContractOrder = FailingContractOfferer(order.offerer)
                .failureReasons(orderHash) != 0;
        }

        // TODO: Think more about inv magic value vs reverts.
        bool isUnauthorizedOrder = false;
        if (order.zone != address(0)) {
            isUnauthorizedOrder = RejectingZone(order.zone)
                .authorizeFailureReasons(orderHash) != 0;
        }

        return (
            block.timestamp >= order.endTime
                || block.timestamp < order.startTime || isCancelled
                || isUnauthorizedOrder
                || isRevertingContractOrder
                || (totalFilled >= totalSize && totalSize > 0)
        );
    }

    function _finalizeZoneParameters(ZoneDetails memory zoneDetails, bool isAuthorize)
        internal
        pure
        returns (ZoneParameters[] memory zoneParameters)
    {
        zoneParameters = new ZoneParameters[](
            zoneDetails.advancedOrders.length
        );

        // Iterate through advanced orders to create zoneParameters
        uint256 totalFulfilled = 0;

        for (uint256 i = 0; i < zoneDetails.advancedOrders.length; i++) {
            if (totalFulfilled >= zoneDetails.maximumFulfilled) {
                break;
            }

            // Trim the length.
            bytes32[] memory orderHashes;

            if (isAuthorize) {
                orderHashes = new bytes32[](i);
                for (uint256 j = 0; j < i; j++) {
                    orderHashes[j] = zoneDetails.orderHashes[j];
                }
            } else {
                orderHashes = zoneDetails.orderHashes;
            }

            // console.log("");
            // console.log("zoneDetails.orderHashes[i]");
            // console.logBytes32(zoneDetails.orderHashes[i]);

            // console.log("isAuthorize");
            // console.log(isAuthorize);

            // console.log("(zoneDetails.orderDetails[i].unavailableReason");
            // console.log(uint256(zoneDetails.orderDetails[i].unavailableReason));

            bool isGoingToBeRejected = zoneDetails.orderDetails[i].unavailableReason
                == UnavailableReason.ZONE_AUTHORIZE_REJECTION;

            if (isAuthorize && isGoingToBeRejected) {
                // Create ZoneParameters and add to zoneParameters array,
                // because we still want to populate the calldataHashes array
                // in getExpectedZoneAuthorizeCalldataHash, but we don't want
                // to increment totalFulfilled.
                zoneParameters[i] = _createZoneParameters(
                    zoneDetails.orderHashes[i],
                    zoneDetails.orderDetails[i],
                    zoneDetails.advancedOrders[i],
                    zoneDetails.fulfiller,
                    orderHashes
                );
            } else if (zoneDetails.orderHashes[i] != bytes32(0)) {
                // Create ZoneParameters and add to zoneParameters array
                zoneParameters[i] = _createZoneParameters(
                    zoneDetails.orderHashes[i],
                    zoneDetails.orderDetails[i],
                    zoneDetails.advancedOrders[i],
                    zoneDetails.fulfiller,
                    orderHashes
                );
                ++totalFulfilled;
            }
        }

        return zoneParameters;
    }

    function _createZoneParameters(
        bytes32 orderHash,
        OrderDetails memory orderDetails,
        AdvancedOrder memory advancedOrder,
        address fulfiller,
        bytes32[] memory orderHashes
    ) internal pure returns (ZoneParameters memory) {
        return ZoneParameters({
            orderHash: orderHash,
            fulfiller: fulfiller,
            offerer: advancedOrder.parameters.offerer,
            offer: orderDetails.offer,
            consideration: orderDetails.consideration,
            extraData: advancedOrder.extraData,
            orderHashes: orderHashes,
            startTime: advancedOrder.parameters.startTime,
            endTime: advancedOrder.parameters.endTime,
            zoneHash: advancedOrder.parameters.zoneHash
        });
    }
}
