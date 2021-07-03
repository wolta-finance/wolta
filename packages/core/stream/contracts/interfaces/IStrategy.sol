// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStrategy {
    function governance() external view returns (address);

    function vault() external view returns (address);

    function underlying() external view returns (address);

    function underlyingBalanceInStrategy() external view returns (uint256);

    function underlyingBalanceInRewardPool() external view returns (uint256);

    function totalUnderlyingBalance() external view returns (uint256);

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function doHardWork() external;
}
