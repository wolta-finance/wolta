// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../utils/UniswapV2Helpers.sol";

import "../interfaces/IVault.sol";
import "../interfaces/uniswap/IUniswapV2Pair.sol";

contract UniswapV2Zap is UniswapV2Helpers {
    using SafeERC20 for IERC20;

    address public governance;
    uint256 public minAmountIn;

    modifier onlyGovernance {
        require(msg.sender == governance, "Not governance");
        _;
    }

    constructor(address governance_, address router_)
        UniswapV2Helpers(router_)
    {
        governance = governance_;
        minAmountIn = 1000;
    }

    function addSwapRoute(
        address fromToken,
        address toToken,
        address[] memory path
    ) public onlyGovernance {
        require(
            swapRoutes[fromToken][toToken].length == 0,
            "Route already exists"
        );

        swapRoutes[fromToken][toToken] = path;
    }

    function removeSwapRoute(address fromToken, address toToken)
        public
        onlyGovernance
    {
        require(
            swapRoutes[fromToken][toToken].length != 0,
            "Route does not exist"
        );

        delete swapRoutes[fromToken][toToken];
    }

    function zapIn(
        address vault,
        address tokenIn,
        uint256 amountIn,
        uint256 minSharesOut
    ) public {
        require(amountIn > minAmountIn, "Insufficient amount in");

        address underlying = IVault(vault).underlying();
        address token0 = IUniswapV2Pair(underlying).token0();
        address token1 = IUniswapV2Pair(underlying).token1();

        require(
            swapRoutes[tokenIn][token0].length != 0,
            "Swap route for token 0 not available"
        );
        require(
            swapRoutes[tokenIn][token1].length != 0,
            "Swap route for token 1 not available"
        );

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 toToken0 = amountIn / 2;
        _swap(toToken0, tokenIn, swapRoutes[tokenIn][token0]);

        uint256 toToken1 = amountIn - toToken0;
        _swap(toToken1, tokenIn, swapRoutes[tokenIn][token1]);

        _addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );

        uint256 underlyingAmount = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeApprove(vault, 0);
        IERC20(underlying).safeApprove(vault, underlyingAmount);
        IVault(vault).deposit(underlyingAmount, msg.sender);

        require(
            IERC20(vault).balanceOf(msg.sender) >= minSharesOut,
            "Insufficient shares out"
        );
    }

    function zapOut(address vault, uint256 shares) public {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);
        IVault(vault).withdraw(shares, address(this));

        address underlying = IVault(vault).underlying();
        address token0 = IUniswapV2Pair(underlying).token0();
        address token1 = IUniswapV2Pair(underlying).token1();

        uint256 underlyingAmount = IERC20(underlying).balanceOf(address(this));
        _removeLiquidity(token0, token1, underlyingAmount);

        IERC20(token0).safeTransfer(
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );

        IERC20(token1).safeTransfer(
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );
    }

    function zapOutAndSwap(
        address vault,
        uint256 shares,
        address tokenOut,
        uint256 minAmountOut
    ) public {
        address underlying = IVault(vault).underlying();
        address token0 = IUniswapV2Pair(underlying).token0();
        address token1 = IUniswapV2Pair(underlying).token1();

        require(
            swapRoutes[token0][tokenOut].length != 0,
            "Swap route for token 0 not available"
        );
        require(
            swapRoutes[token1][tokenOut].length != 0,
            "Swap route for token 1 not available"
        );

        IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);
        IVault(vault).withdraw(shares, address(this));

        uint256 underlyingAmount = IERC20(underlying).balanceOf(address(this));
        _removeLiquidity(token0, token1, underlyingAmount);

        _swap(
            IERC20(token0).balanceOf(address(this)),
            tokenOut,
            swapRoutes[token0][tokenOut]
        );

        _swap(
            IERC20(token1).balanceOf(address(this)),
            tokenOut,
            swapRoutes[token1][tokenOut]
        );

        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient amount out");

        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
    }
}
