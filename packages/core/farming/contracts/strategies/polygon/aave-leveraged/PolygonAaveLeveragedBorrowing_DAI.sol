// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../../../Vault.sol";
import "./PolygonAaveLeveragedBorrowing.sol";

contract PolygonAaveLeveragedBorrowing_DAI_Vault is Vault {
    address public constant dai =
        address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);

    constructor(address controller_) Vault(controller_, dai, 1e18) {}
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
