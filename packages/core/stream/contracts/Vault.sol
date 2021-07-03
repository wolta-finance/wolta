// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./utils/ERC20WithDecimals.sol";

import "./interfaces/IController.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";

contract Vault is IVault {
    using SafeERC20 for IERC20;

    address public override controller;
    address public override strategy;
    address public override underlying;
    uint256 public override investmentPercentage;

    modifier onlyGovernance {
        require(msg.sender == governance(), "Not governance");
        _;
    }

    modifier onlyControllerOrGovernance {
        require(
            msg.sender == controller || msg.sender == governance(),
            "Not controller or governance"
        );
        _;
    }

    modifier whenStrategyDefined {
        require(strategy != address(0), "Strategy not defined");
        _;
    }

    constructor(
        address controller_,
        address underlying_,
        uint256 investmentPercentage_
    ) {
        require(investmentPercentage_ <= 1e18, "Invalid investment percentage");

        controller = controller_;
        underlying = underlying_;
        investmentPercentage = investmentPercentage_;
    }

    function governance() public view override returns (address) {
        return IController(controller).governance();
    }

    function underlyingBalanceInVault() public view override returns (uint256) {
        return IERC20(underlying).balanceOf(address(this));
    }

    function underlyingBalanceInStrategy()
        public
        view
        override
        returns (uint256)
    {
        if (strategy == address(0)) {
            return 0;
        }
        return IStrategy(strategy).totalUnderlyingBalance();
    }

    function totalUnderlyingBalance() public view override returns (uint256) {
        return underlyingBalanceInVault() + underlyingBalanceInStrategy();
    }

    function availableToInvest() public view override returns (uint256) {
        uint256 balanceAvailableToInvest = (totalUnderlyingBalance() *
            investmentPercentage) / 1e18;
        uint256 balanceAlreadyInvested = underlyingBalanceInStrategy();

        if (balanceAlreadyInvested >= balanceAvailableToInvest) {
            return 0;
        }
        return
            Math.min(
                balanceAvailableToInvest - balanceAlreadyInvested,
                underlyingBalanceInVault()
            );
    }

    function setStrategy(address strategy_)
        public
        override
        onlyControllerOrGovernance
    {
        require(
            IStrategy(strategy_).underlying() == underlying,
            "Underlying does not match"
        );

        if (strategy != address(0)) {
            IStrategy(strategy).withdrawAll();
        }

        strategy = strategy_;
    }

    function setInvestmentPercentage(uint256 investmentPercentage_)
        public
        override
        onlyGovernance
    {
        require(investmentPercentage_ <= 1e18, "Invalid investment percentage");

        investmentPercentage = investmentPercentage_;
    }

    function rebalance()
        public
        override
        onlyControllerOrGovernance
        whenStrategyDefined
    {
        IStrategy(strategy).withdrawAll();
        _invest();
    }

    function doHardWork()
        public
        override
        onlyControllerOrGovernance
        whenStrategyDefined
    {
        _invest();
        IStrategy(strategy).doHardWork();
    }

    function _invest() internal {
        uint256 amountToInvest = availableToInvest();
        if (amountToInvest > 0) {
            IERC20(underlying).safeTransfer(strategy, amountToInvest);
        }
    }
}
