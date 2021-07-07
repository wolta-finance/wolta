// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperTokenFactory} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "../../../SuperVault.sol";
import "./PolygonAaveLeveragedBorrowing.sol";

contract PolygonAaveLeveragedBorrowing_DAI_Vault is SuperVault {
    address public constant dai =
        address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);

    constructor(
        ISuperfluid host_,
        IConstantFlowAgreementV1 cfa_,
        ISuperToken acceptedToken_,
        ISuperToken sybToken_,
        address controller_
    )
        SuperVault(
            host_,
            cfa_,
            acceptedToken_,
            sybToken_,
            controller_,
            dai,
            1e18
        )
    {}
}

contract PolygonAaveLeveragedBorrowing_DAI is PolygonAaveLeveragedBorrowing {
    address public constant wmatic =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public constant weth =
        address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address public constant dai =
        address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);

    // uint256 public constant minLeverage_ = 1e18;
    // uint256 public constant borrowDepth_ = 6;

    constructor(address vault_) PolygonAaveLeveragedBorrowing(vault_, 1000, 6) {
        swapRoutes[wmatic][dai] = [wmatic, weth, dai];
    }
}
