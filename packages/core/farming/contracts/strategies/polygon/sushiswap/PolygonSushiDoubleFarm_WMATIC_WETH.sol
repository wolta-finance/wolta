// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../../../Vault.sol";
import "./PolygonSushiDoubleFarm.sol";

contract PolygonSushiDoubleFarm_WMATIC_WETH_Vault is Vault {
    address public constant wmaticWethSlp =
        address(0xc4e595acDD7d12feC385E5dA5D43160e8A0bAC0E);

    constructor(address controller_) Vault(controller_, wmaticWethSlp, 1e18) {}
}

contract PolygonSushiDoubleFarm_WMATIC_WETH is PolygonSushiDoubleFarm {
    address public constant wmatic =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public constant weth =
        address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address public constant sushi =
        address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);

    constructor(address vault_)
        PolygonSushiDoubleFarm(
            vault_,
            0, // reward pool id
            wmatic, // lp token 0
            weth, // lp token 1
            sushi, // reward token 0
            wmatic // reward token 1
        )
    {
        swapRoutes[sushi][wmatic] = [sushi, weth, wmatic];
        swapRoutes[sushi][weth] = [sushi, weth];
        swapRoutes[wmatic][wmatic] = [wmatic];
        swapRoutes[wmatic][weth] = [wmatic, weth];
    }
}
