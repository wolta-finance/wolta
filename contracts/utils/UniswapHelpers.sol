// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/uniswap/IUniswapV2Router02.sol";

abstract contract UniswapHelpers {
    using SafeERC20 for IERC20;

    // --------------- Fields ---------------

    address private _router;

    // --------------- Constructor ---------------

    constructor(address router) {
        _router = router;
    }

    // --------------- Internal ---------------

    function _swap(
        uint256 amount,
        address token,
        address[] memory route
    ) internal {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Insufficient amount"
        );

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

    function _provideLiquidity(
        address token0,
        address token1,
        uint256 amountToken0,
        uint256 amountToken1
    ) internal {
        require(
            IERC20(token0).balanceOf(address(this)) >= amountToken0,
            "Insufficient token 0 amount"
        );
        require(
            IERC20(token1).balanceOf(address(this)) >= amountToken1,
            "Insufficient token 1 amount"
        );

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
}
