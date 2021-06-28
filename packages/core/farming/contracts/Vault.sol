// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./utils/ERC20WithDecimals.sol";

import "./interfaces/IController.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";

contract Vault is ERC20WithDecimals, IVault {
    using SafeERC20 for IERC20;

    address public override controller;
    address public override strategy;
    address public override underlying;
    uint256 public override investmentPercentage;

    uint256 private _underlyingUnit;

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
    )
        ERC20WithDecimals(
            string(abi.encodePacked("TBD ", ERC20(underlying_).name())),
            string(abi.encodePacked("t", ERC20(underlying_).symbol())),
            ERC20(underlying_).decimals()
        )
    {
        require(investmentPercentage_ <= 1e18, "Invalid investment percentage");

        controller = controller_;
        underlying = underlying_;
        investmentPercentage = investmentPercentage_;

        _underlyingUnit = 10**uint256(ERC20(underlying_).decimals());
    }

    function governance() public view override returns (address) {
        return IController(controller).governance();
    }

    function pricePerShare() public view override returns (uint256) {
        if (totalSupply() == 0) {
            return _underlyingUnit;
        }
        return (_underlyingUnit * totalUnderlyingBalance()) / totalSupply();
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
        uint256 balanceAvailableToInvest =
            (totalUnderlyingBalance() * investmentPercentage) / 1e18;
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

    function deposit(uint256 amount, address to)
        public
        override
        whenStrategyDefined
    {
        require(amount > 0, "Cannot deposit zero");
        require(to != address(0), "Recipient cannot be address zero");

        uint256 sharesTotalSupply = totalSupply();
        uint256 sharesToMint =
            sharesTotalSupply == 0
                ? amount
                : (amount * sharesTotalSupply) / totalUnderlyingBalance();
        _mint(to, sharesToMint);

        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 shares, address to)
        public
        override
        whenStrategyDefined
    {
        require(shares > 0, "Cannot withdraw zero");
        require(to != address(0), "Recipient cannot be address zero");

        uint256 sharesTotalSupply = totalSupply();
        _burn(msg.sender, shares);

        uint256 amountToWithdraw =
            (totalUnderlyingBalance() * shares) / sharesTotalSupply;
        if (amountToWithdraw > underlyingBalanceInVault()) {
            IStrategy(strategy).withdraw(
                amountToWithdraw - underlyingBalanceInVault()
            );
        }

        IERC20(underlying).safeTransfer(to, amountToWithdraw);
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
