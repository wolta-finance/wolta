// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../../utils/UniswapV2Helpers.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IVault.sol";
import "../../../interfaces/aave/IAaveIncentivesController.sol";
import "../../../interfaces/aave/IAaveProtocolDataProvider.sol";
import "../../../interfaces/aave/ILendingPool.sol";

contract PolygonAaveLending is UniswapV2Helpers, IStrategy {
    using SafeERC20 for IERC20;

    address public override vault;
    address public override underlying;

    address public aToken;
    address public rewardToken;

    address public constant lendingPool =
        address(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    address public constant incentivesController =
        address(0x357D51124f59836DeD84c8a1730D72B749d8BC23);

    address public constant dataProvider =
        address(0x7551b5D2763519d4e37e8B81929D336De671d46d);

    address public constant sushiSwapRouter =
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    modifier onlyGovernance {
        require(
            msg.sender == vault || msg.sender == governance(),
            "Not governance"
        );
        _;
    }

    modifier onlyVaultOrGovernance {
        require(
            msg.sender == vault || msg.sender == governance(),
            "Not vault or governance"
        );
        _;
    }

    constructor(address vault_) UniswapV2Helpers(sushiSwapRouter) {
        vault = vault_;
        underlying = IVault(vault).underlying();

        (aToken, , ) = IAaveProtocolDataProvider(dataProvider)
            .getReserveTokensAddresses(underlying);
        rewardToken = IAaveIncentivesController(incentivesController)
            .REWARD_TOKEN();
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
        returns (uint256 amount)
    {
        return IERC20(aToken).balanceOf(address(this));
    }

    function totalUnderlyingBalance() public view override returns (uint256) {
        return underlyingBalanceInStrategy() + underlyingBalanceInRewardPool();
    }

    function withdraw(uint256 amount) public override onlyVaultOrGovernance {
        if (amount > underlyingBalanceInStrategy()) {
            uint256 amountToWithdraw = amount - underlyingBalanceInStrategy();
            ILendingPool(lendingPool).withdraw(
                underlying,
                Math.min(amountToWithdraw, underlyingBalanceInRewardPool()),
                address(this)
            );
        }

        IERC20(underlying).safeTransfer(vault, amount);
    }

    function withdrawAll() public override onlyVaultOrGovernance {
        _exitRewardPool();
        _liquidateReward();
        IERC20(underlying).safeTransfer(vault, underlyingBalanceInStrategy());
    }

    function doHardWork() public override onlyVaultOrGovernance {
        _claimReward();
        _liquidateReward();
        _enterRewardPool();
    }

    function _enterRewardPool() internal {
        uint256 amountToInvest = underlyingBalanceInStrategy();
        if (amountToInvest > 0) {
            IERC20(underlying).safeApprove(lendingPool, 0);
            IERC20(underlying).safeApprove(lendingPool, amountToInvest);
            ILendingPool(lendingPool).deposit(
                underlying,
                amountToInvest,
                address(this),
                0
            );
        }
    }

    function _exitRewardPool() internal {
        uint256 amountInvested = underlyingBalanceInRewardPool();
        if (amountInvested > 0) {
            ILendingPool(lendingPool).withdraw(
                underlying,
                amountInvested,
                address(this)
            );
        }
    }

    function _claimReward() internal {
        address[] memory assets = new address[](1);
        assets[0] = aToken;

        IAaveIncentivesController(incentivesController).claimRewards(
            assets,
            type(uint256).max,
            address(this)
        );
    }

    function _liquidateReward() internal {
        uint256 reward = IERC20(rewardToken).balanceOf(address(this));
        _swap(reward, rewardToken, swapRoutes[rewardToken][underlying]);
    }
}
