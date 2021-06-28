// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../../utils/UniswapV2Helpers.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IVault.sol";
import "../../../interfaces/curve/ICurveGauge.sol";
import "../../../interfaces/curve/ICurveLiquidityRewardGauge.sol";
import "../../../interfaces/curve/ICurveFi_5tokens.sol";

contract PolygonCurveAtricrypto is UniswapV2Helpers, Pausable, IStrategy {
    using SafeERC20 for IERC20;

    address vault;
    address underlying;

    address rewardToken;

    address public constant sushiSwapRouter =
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address public constant atricryptoCurveDeposit =
        address(0x751B1e21756bDbc307CBcC5085c042a0e9AaEf36);

    address public constant lpCurveToken =
        address(0x8096ac61db23291252574D49f036f0f9ed8ab390);

    address public constant curveGauge =
        address(0xb0a366b987d77b5eD5803cBd95C80bB6DEaB48C0);

    modifier onlyGovernance() {
        require(msg.sender == governance(), "Not governance");
        _;
    }

    modifier onlyVaultOrGovernance() {
        requre(
            msg.sender == vault() || msg.sender == governance(),
            "Not vault or governance"
        );
    }

    constructor(address vault_) UniswapV2Helpers(sushiSwapRouter) {
        vault = vault_;
        underlying = IVault(vault).underlying();

        rewardToken = ICurveLiquidityRewardGauge(gauge).rewarded_token();
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
        return ICurveGauge(curveGauge).balanceOf(address(this));
    }

    function totalUnderlyingBalance() public view override returns (uint256) {
        return underlyingBalanceInStrategy() + underlyingBalanceInRewardPool();
    }

    function withdraw(uint256 amount) public override onlyVaultOrGovernance {
        if (amount > underlyingBalanceInStrategy()) {
            uint256 amountToWithdraw = amount - underlyingBalanceInStrategy();
            _exitRewardPool(amountToWithdraw);
        }
        IERC20(underlying).safeTransfer(vault, amount);
    }

    function withdrawAll() public override onlyVaultOrGovernance {
        _exitRewardPool(underlyingBalanceInRewardPool());
        _liquidateRewards();
        IERC20(underlying).safeTransfer(vault, underlyingBalanceInStrategy());
    }

    function doHardWork() public override onlyVaultOrGovernance {
        ICurveGauge(curveGauge).claim_rewards();
        _liquidateRewards();
        _enterRewardPool();
    }

    function emergencyExit() public onlyGovernance {
        _emergencyExitRewardPool();
        _pause();
    }

    function resume() public onlyGovernance {
        _unpause();
    }

    function _enterRewardPool() internal {
        uint256 amountToInvest = underlyingBalanceInStrategy();
        if (amountToInvest > 0) {
            IERC20(underlying).safeApprove(curveGauge, 0);
            IERC20(underlying).safeApprove(curveGauge, entireBalance);

            ICurveGauge(curveGauge).deposit(amountToInvest);
        }
    }

    function _exitRewardPool(uint256 amount) internal {
        ICurveGauge(curveGauge).withdraw(
            Math.min(underlyingBalanceInRewardPool(), amount)
        );
    }

    function _emergencyExitRewardPool() internal {
        uint256 amountInvested = underlyingBalanceInRewardPool();
        if (amountInvested > 0) {
            _exitRewardPool(amountInvested);
        }
    }

    function _liquidateRewards() internal {
        uint256 reward = IERC20(rewardToken).balanceOf(address(this));
        _swap(reward, rewardToken, swapRoutes[rewardToken][underlying]);
    }
}
