// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IUniswapV2Pair {
    // --------------- Views ---------------

    function token0() external view returns (address);

    function token1() external view returns (address);
}
