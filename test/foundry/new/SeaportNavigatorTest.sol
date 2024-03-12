// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    CriteriaHelper
} from "../../../src/main/helpers/navigator/lib/CriteriaHelper.sol";

import {
    ExecutionsHelper
} from "../../../src/main/helpers/navigator/lib/ExecutionsHelper.sol";

import {
    FulfillmentsHelper
} from "../../../src/main/helpers/navigator/lib/FulfillmentsHelper.sol";

import {
    HelperInterface
} from "../../../src/main/helpers/navigator/lib/HelperInterface.sol";

import {
    OrderDetailsHelper
} from "../../../src/main/helpers/navigator/lib/OrderDetailsHelper.sol";

import {
    RequestValidator
} from "../../../src/main/helpers/navigator/lib/RequestValidator.sol";

import {
    SeaportNavigator
} from "../../../src/main/helpers/navigator/SeaportNavigator.sol";

import {
    SuggestedActionHelper
} from "../../../src/main/helpers/navigator/lib/SuggestedActionHelper.sol";

import {
    ValidatorHelper
} from "../../../src/main/helpers/navigator/lib/ValidatorHelper.sol";

contract SeaportNavigatorTest {
    HelperInterface internal requestValidator = new RequestValidator();
    HelperInterface internal criteriaHelper = new CriteriaHelper();
    HelperInterface internal validatorHelper = new ValidatorHelper();
    HelperInterface internal orderDetailsHelper = new OrderDetailsHelper();
    HelperInterface internal fulfillmentsHelper = new FulfillmentsHelper();
    HelperInterface internal suggestedActionHelper =
        new SuggestedActionHelper();
    HelperInterface internal executionsHelper = new ExecutionsHelper();

    // Initialize the navigator with all its constituent helpers.
    SeaportNavigator internal navigator =
        new SeaportNavigator(
            address(requestValidator),
            address(criteriaHelper),
            address(validatorHelper),
            address(orderDetailsHelper),
            address(fulfillmentsHelper),
            address(suggestedActionHelper),
            address(executionsHelper)
        );
}
