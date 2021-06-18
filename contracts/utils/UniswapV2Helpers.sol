// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/uniswap/IUniswapV2Factory.sol";
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";

abstract contract UniswapV2Helpers {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => address[])) swapRoutes;

    address private _router;

    constructor(address router_) {
        _router = router_;
    }

    function _swap(
        uint256 amount,
        address token,
        address[] memory route
    ) internal {
        if (amount > 0 && route.length > 1) {
            IERC20(token).safeApprove(_router, 0);
            IERC20(token).safeApprove(_router, amount);

            IUniswapV2Router02(_router).swapExactTokensForTokens(
                amount,
                1,
                route,
                address(this),
                block.timestamp
            );
        }
    }

    function _addLiquidity(
        address token0,
        address token1,
        uint256 amountToken0,
        uint256 amountToken1
    ) internal {
        if (amountToken0 > 0 && amountToken1 > 0) {
            IERC20(token0).safeApprove(_router, 0);
            IERC20(token0).safeApprove(_router, amountToken0);

            IERC20(token1).safeApprove(_router, 0);
            IERC20(token1).safeApprove(_router, amountToken1);

            IUniswapV2Router02(_router).addLiquidity(
                token0,
                token1,
                amountToken0,
                amountToken1,
                1,
                1,
                address(this),
                block.timestamp
            );
        }
    }

    function _removeLiquidity(
        address token0,
        address token1,
        uint256 amount
    ) internal {
        if (amount > 0) {
            address factory = IUniswapV2Router02(_router).factory();
            address underlying =
                IUniswapV2Factory(factory).getPair(token0, token1);

            IERC20(underlying).safeApprove(_router, 0);
            IERC20(underlying).safeApprove(_router, amount);

            IUniswapV2Router02(_router).removeLiquidity(
                token0,
                token1,
                amount,
                1,
                1,
                address(this),
                block.timestamp
            );
        }
    }
}
