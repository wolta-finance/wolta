// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../../utils/UniswapV2Helpers.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IVault.sol";
import "../../../interfaces/sushiswap/IMiniChefV2.sol";

contract PolygonSushiDoubleFarm is UniswapV2Helpers, Pausable, IStrategy {
    using SafeERC20 for IERC20;

    address public override vault;
    address public override underlying;

    uint256 public pid;
    address public token0;
    address public token1;
    address public rewardToken0;
    address public rewardToken1;

    address public constant miniChefV2 =
        address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);

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

    constructor(
        address vault_,
        uint256 pid_,
        address token0_,
        address token1_,
        address rewardToken0_,
        address rewardToken1_
    ) UniswapV2Helpers(sushiSwapRouter) {
        vault = vault_;
        underlying = IVault(vault).underlying();

        require(
            IMiniChefV2(miniChefV2).lpToken(pid) == underlying,
            "Pool id does not match underlying"
        );
        require(
            IUniswapV2Pair(underlying).token0() == token0_,
            "Token 0 does not match underlying"
        );
        require(
            IUniswapV2Pair(underlying).token1() == token1_,
            "Token 1 does not match underlying"
        );

        pid = pid_;
        token0 = token0_;
        token1 = token1_;
        rewardToken0 = rewardToken0_;
        rewardToken1 = rewardToken1_;
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
        (amount, ) = IMiniChefV2(miniChefV2).userInfo(pid, address(this));
    }

    function totalUnderlyingBalance() public view override returns (uint256) {
        return underlyingBalanceInStrategy() + underlyingBalanceInRewardPool();
    }

    function withdraw(uint256 amount) public override onlyVaultOrGovernance {
        if (amount > underlyingBalanceInStrategy()) {
            uint256 amountToWithdraw = amount - underlyingBalanceInStrategy();
            IMiniChefV2(miniChefV2).withdraw(
                pid,
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

    function doHardWork() public override onlyVaultOrGovernance whenNotPaused {
        _claimReward();
        _liquidateReward();
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
            IERC20(underlying).safeApprove(miniChefV2, 0);
            IERC20(underlying).safeApprove(miniChefV2, amountToInvest);
            IMiniChefV2(miniChefV2).deposit(pid, amountToInvest, address(this));
        }
    }

    function _exitRewardPool() internal {
        uint256 amountInvested = underlyingBalanceInRewardPool();
        if (amountInvested > 0) {
            IMiniChefV2(miniChefV2).withdraw(
                pid,
                amountInvested,
                address(this)
            );
        }
    }

    function _emergencyExitRewardPool() internal {
        uint256 amountInvested = underlyingBalanceInRewardPool();
        if (amountInvested > 0) {
            IMiniChefV2(miniChefV2).emergencyWithdraw(pid, address(this));
        }
    }

    function _claimReward() internal {
        IMiniChefV2(miniChefV2).harvest(pid, address(this));
    }

    function _liquidateReward() internal {
        uint256 reward0 = IERC20(rewardToken0).balanceOf(address(this));
        {
            uint256 toToken0 = reward0 / 2;
            _swap(toToken0, rewardToken0, swapRoutes[rewardToken0][token0]);

            uint256 toToken1 = reward0 - toToken0;
            _swap(toToken1, rewardToken0, swapRoutes[rewardToken0][token1]);
        }

        uint256 reward1 = IERC20(rewardToken1).balanceOf(address(this));
        {
            uint256 toToken0 = reward1 / 2;
            _swap(toToken0, rewardToken1, swapRoutes[rewardToken1][token0]);

            uint256 toToken1 = reward1 - toToken0;
            _swap(toToken1, rewardToken1, swapRoutes[rewardToken1][token1]);
        }

        _addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }
}
