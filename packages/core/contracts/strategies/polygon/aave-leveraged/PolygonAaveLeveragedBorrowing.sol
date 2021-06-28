// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IVault.sol";

import "../../../utils/UniswapV2Helpers.sol";

import "../../../interfaces/aave/IAaveIncentivesController.sol";
import "../../../interfaces/aave/IAaveProtocolDataProvider.sol";
import "../../../interfaces/aave/ILendingPool.sol";

contract PolygonAaveLeveragedBorrowing is
    Pausable,
    IStrategy,
    UniswapV2Helpers
{
    using SafeERC20 for IERC20;

    address public override vault;
    address public override underlying;

    address public aToken;
    address public debtToken;
    address public rewardToken;

    address public constant lendingPool =
        address(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    address public constant incentivesController =
        address(0x357D51124f59836DeD84c8a1730D72B749d8BC23);
    address public constant dataProvider =
        address(0x7551b5D2763519d4e37e8B81929D336De671d46d);

    address public constant sushiSwapRouter =
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    // Profitability vars
    uint256 public borrowRate; // amount of collateral we borrow per leverage level
    uint256 public borrowRateMax;
    uint256 public borrowDepth;
    uint256 public minLeverage;
    uint256 public BORROW_DEPTH_MAX = 10;
    uint256 public constant INTEREST_RATE_MODE = 2; // variable; 1 - stable
    uint256 public constant MIN_HEALTH_FACTOR = 1.1e18; // 1.1%

    modifier onlyGovernance {
        require(msg.sender == governance(), "Not governance");
        _;
    }

    modifier onlyVaultOrGovernance {
        require(
            msg.sender == vault || msg.sender == governance(),
            "Not vault or governance"
        );
        _;
    }

    constructor(
        address vault_,
        uint256 minLeverage_,
        uint256 borrowDepth_
    ) UniswapV2Helpers(sushiSwapRouter) {
        vault = vault_;
        minLeverage = minLeverage_;
        borrowDepth = borrowDepth_;
        underlying = IVault(vault).underlying();

        (aToken, , debtToken) = IAaveProtocolDataProvider(dataProvider)
        .getReserveTokensAddresses(underlying);
        rewardToken = IAaveIncentivesController(incentivesController)
        .REWARD_TOKEN();

        // Get the borrowRateMax we can use
        (
            ,
            uint256 ltv,
            uint256 threshold,
            ,
            ,
            bool collateral,
            bool borrow,
            ,
            ,

        ) = IAaveProtocolDataProvider(dataProvider).getReserveConfigurationData(
            underlying
        );
        borrowRateMax = ltv.mul(99).div(100); // 1% of ltv
        // At minimum, borrow rate always 10% lower than liquidation threshold
        if (threshold.mul(9).div(10) > borrowRateMax) {
            borrowRate = borrowRateMax.div(100); // 7500 -> 75
        } else {
            borrowRate = threshold.mul(9).div(10).div(100);
        }

        // Only leverage if you can
        if (!(collateral && borrow)) {
            borrowDepth = 0;
            BORROW_DEPTH_MAX = 0;
        }
    }

    function governance() public view override returns (address) {
        return IVault(vault).governance();
    }

    function underlyingBalanceInStrategy()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(underlying).balanceOf(address(this));
    }

    function underlyingBalanceInRewardPool()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(aToken).balanceOf(address(this));
    }

    function underlyingBalanceInDebt() public view returns (uint256) {
        return IERC20(debtToken).balanceOf(address(this));
    }

    function totalUnderlyingBalance() public view override returns (uint256) {
        return
            underlyingBalanceInStrategy() +
            underlyingBalanceInRewardPool() -
            underlyingBalanceInDebt();
    }

    function withdraw(uint256 amount) public override onlyVaultOrGovernance {
        if (amount > underlyingBalanceInStrategy()) {
            if (
                (currentHealthFactor() <= MIN_HEALTH_FACTOR) ||
                amount.mul(2) >= underlyingBalanceInStrategy()
            ) {
                // check if the health factor doesn't allow for partialDeleverage or if there are too many loops in partialDeleverage
                _fullDeleverage();
            } else {
                _partialDeleverage(amount);
            }
        }

        IERC20(underlying).safeTransfer(vault, amount);
    }

    function withdrawAll() public override onlyVaultOrGovernance {
        _fullDeleverage();
        _liquidateReward();
        IERC20(underlying).safeTransfer(vault, underlyingBalanceInStrategy());
    }

    function doHardWork() public override onlyVaultOrGovernance {
        _claimReward();
        _liquidateReward();
        _enterRewardPool();
    }

    function emergencyExit() public onlyGovernance {
        _pause();
        _fullDeleverage();
    }

    function resume() public onlyGovernance {
        _unpause();
    }

    function rebalance(uint256 borrowRate_, uint256 borrowDepth_)
        external
        onlyVaultOrGovernance
    {
        require(
            borrowRate_ <= borrowRateMax,
            "borrowRate is bigger than the allowed borrowRateMax "
        );
        require(borrowRate_ != 0, "borrowRate cannot be 0");
        require(
            borrowDepth_ <= BORROW_DEPTH_MAX,
            "borrowDepth is bigger than the allowed BORROW_DEPTH_MAX"
        );

        _fullDeleverage();
        borrowRate = borrowRate_;
        borrowDepth = borrowDepth_;
        _enterRewardPool();
    }

    function increaseHealthFactor() external onlyVaultOrGovernance {
        (uint256 supplyBal, ) = supplyAndDebt();

        // Only withdraw the 10% of the max withdraw
        uint256 toWithdraw = _maxWithdrawFromSupply(supplyBal).mul(100).div(10);

        ILendingPool(lendingPool).withdraw(
            underlying,
            toWithdraw,
            address(this)
        );
        ILendingPool(lendingPool).repay(
            underlying,
            toWithdraw,
            INTEREST_RATE_MODE,
            address(this)
        );
    }

    function _claimReward() internal {
        address[] memory assets = new address[](2);
        assets[0] = aToken;
        assets[1] = debtToken;
        IAaveIncentivesController(incentivesController).claimRewards(
            assets,
            type(uint256).max,
            address(this)
        );
    }

    function _enterRewardPool() internal {
        uint256 amountToInvest = underlyingBalanceInStrategy();

        if (amountToInvest > 0) {
            _giveAllowance();
            ILendingPool(lendingPool).deposit(
                underlying,
                amountToInvest,
                address(this),
                0
            );
            if (amountToInvest > minLeverage) {
                for (uint256 i = 0; i < borrowDepth; i++) {
                    amountToInvest = amountToInvest.mul(borrowRate).div(100);
                    ILendingPool(lendingPool).borrow(
                        underlying,
                        amountToInvest,
                        INTEREST_RATE_MODE,
                        0,
                        address(this)
                    );
                    ILendingPool(lendingPool).deposit(
                        underlying,
                        amountToInvest,
                        address(this),
                        0
                    );

                    if (amountToInvest < minLeverage) {
                        break;
                    }
                }
            }
        }
    }

    function _liquidateReward() internal {
        uint256 reward = IERC20(rewardToken).balanceOf(address(this));
        _swap(reward, rewardToken, swapRoutes[rewardToken][underlying]);
    }

    // Divide the supply with HF less 0.5 to finish at least with HF~=1.05
    function _maxWithdrawFromSupply(uint256 _supply)
        internal
        view
        returns (uint256)
    {
        // The healthFactor value has the same representation than supply so
        // to do the math we should remove 12 places from healthFactor to get a HF
        // with only 6 "decimals" and add 6 "decimals" to supply to divide like we do IRL.
        return
            _supply.sub(
                _supply.mul(1e6).div(
                    currentHealthFactor().div(1e12).sub(0.10e6)
                )
            );
    }

    function _partialDeleverage(uint256 amount_) internal {
        uint256 supplyBal;
        uint256 debtBal;
        uint256 toWithdraw;
        uint256 toRepay;

        IERC20(underlying).safeApprove(lendingPool, 0);
        IERC20(underlying).safeApprove(lendingPool, type(uint256).max);

        while (underlyingBalanceInStrategy() < amount_) {
            (supplyBal, debtBal) = supplyAndDebt();
            toWithdraw = _maxWithdrawFromSupply(supplyBal);
            ILendingPool(lendingPool).withdraw(
                underlying,
                toWithdraw,
                address(this)
            );

            if (debtBal > 0) {
                // Only repay the just amount
                toRepay = toWithdraw.mul(borrowRate).div(100);
                ILendingPool(lendingPool).repay(
                    underlying,
                    toRepay,
                    INTEREST_RATE_MODE,
                    address(this)
                );
            }
        }
        IERC20(underlying).safeApprove(lendingPool, 0);
    }

    function _fullDeleverage() internal {
        (uint256 supplyBal, uint256 debtBal) = supplyAndDebt();
        uint256 toWithdraw;
        IERC20(underlying).safeApprove(lendingPool, 0);
        IERC20(underlying).safeApprove(lendingPool, debtBal);
        while (debtBal > 0) {
            toWithdraw = _maxWithdrawFromSupply(supplyBal);

            ILendingPool(lendingPool).withdraw(
                underlying,
                toWithdraw,
                address(this)
            );
            // Repay only will use the needed
            ILendingPool(lendingPool).repay(
                underlying,
                toWithdraw,
                INTEREST_RATE_MODE,
                address(this)
            );

            (supplyBal, debtBal) = supplyAndDebt();
        }

        if (supplyBal > 0) {
            ILendingPool(lendingPool).withdraw(
                underlying,
                type(uint256).max,
                address(this)
            );
        }
    }

    function _giveAllowance() internal {
        uint256 amountToAllow = underlyingBalanceInStrategy();
        uint256 amountToAdd = amountToAllow;
        for (uint256 i = 0; i < borrowRate; i++) {
            amountToAdd = amountToAdd.mul(borrowRate).div(100);
            amountToAllow += amountToAdd;
        }
        IERC20(underlying).safeApprove(lendingPool, 0);
        IERC20(underlying).safeApprove(lendingPool, amountToAllow);
    }

    function currentHealthFactor() public view returns (uint256) {
        (, , , , , uint256 healthFactor) = ILendingPool(lendingPool)
        .getUserAccountData(address(this));

        return healthFactor;
    }

    function supplyAndDebt() public view returns (uint256, uint256) {
        (
            uint256 supplyBal,
            ,
            uint256 debtBal,
            ,
            ,
            ,
            ,
            ,

        ) = IAaveProtocolDataProvider(dataProvider).getUserReserveData(
            underlying,
            address(this)
        );
        return (supplyBal, debtBal);
    }
}
