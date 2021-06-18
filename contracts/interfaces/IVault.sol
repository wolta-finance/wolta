// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVault {
    // --------------- Views ---------------

    function controller() external view returns (address);

    function strategy() external view returns (address);

    function underlying() external view returns (address);

    function investmentPercentage() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceInStrategy() external view returns (uint256);

    function totalUnderlyingBalance() external view returns (uint256);

    function availableToInvest() external view returns (uint256);

    // --------------- Actions ---------------

    function setStrategy(address strategy_) external;

    function setInvestmentPercentage(uint256 investmentPercentage_) external;

    function deposit(uint256 amount, address to) external;

    function withdraw(uint256 shares, address to) external;

    function rebalance() external;

    function doHardWork() external;
}
