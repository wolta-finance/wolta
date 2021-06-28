// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../Vault.sol";
import "./PolygonCurveAtricrypto.sol";

contract PolygonCurveAtricrypto_USDC_Vault is Vault {
    address public constant usdc =
        address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    constructor(address controller_) Vault(controller_, usdc, 1e18) {}
}

contract PolygonCurveAtricrypto_USDC is PolygonCurveAtricrypto {
    address public constant wmatic =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public constant weth =
        address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address public constant usdc =
        address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    constructor(address vault_) PolygonCurveAtricrypto(vault_) {
        swapRoutes[wmatic][usdc] = [wmatic, weth, usdc];
    }
}
