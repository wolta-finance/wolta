// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVault {
    function governance() external view returns (address);

    function controller() external view returns (address);

    function strategy() external view returns (address);

    function underlying() external view returns (address);

    function investmentPercentage() external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceInStrategy() external view returns (uint256);

    function totalUnderlyingBalance() external view returns (uint256);

    function availableToInvest() external view returns (uint256);

    function setStrategy(address strategy_) external;

    function setInvestmentPercentage(uint256 investmentPercentage_) external;

    function rebalance() external;

    function doHardWork() external;
}
