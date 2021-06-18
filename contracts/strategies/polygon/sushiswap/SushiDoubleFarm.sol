// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../../utils/UniswapHelpers.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/sushiswap/IMiniChefV2.sol";
import "../../../interfaces/uniswap/IUniswapV2Pair.sol";
import "../../../interfaces/uniswap/IUniswapV2Router02.sol";

contract SushiDoubleFarm is UniswapHelpers, Pausable, IStrategy {
    using SafeERC20 for IERC20;

    // --------------- Fields ---------------

    address public governance;

    address public override vault;
    address public override underlying;

    uint256 public pid;
    address public token0;
    address public token1;
    address public rewardToken0;
    address public rewardToken1;
    mapping(address => mapping(address => address[])) swapRoutes;

    // --------------- Constants ---------------

    address public constant miniChefV2 =
        address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);

    address public constant sushiSwapRouter =
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    // --------------- Events ---------------

    // --------------- Modifiers ---------------

    modifier onlyGovernance {
        require(msg.sender == governance, "Not governance");
        _;
    }

    modifier onlyVaultOrGovernance {
        require(
            msg.sender == vault || msg.sender == governance,
            "Not vault or governance"
        );
        _;
    }

    // --------------- Constructor ---------------

    constructor(
        address governance_,
        address vault_,
        address underlying_,
        uint256 pid_,
        address token0_,
        address token1_,
        address rewardToken0_,
        address rewardToken1_
    ) UniswapHelpers(sushiSwapRouter) {
        require(
            IMiniChefV2(miniChefV2).lpToken(pid) == underlying_,
            "Pool id does not match underlying"
        );
        require(
            IUniswapV2Pair(underlying_).token0() == token0_,
            "Token 0 does not match underlying LP token"
        );
        require(
            IUniswapV2Pair(underlying_).token1() == token1_,
            "Token 1 does not match underlying LP token"
        );

        governance = governance_;

        vault = vault_;
        underlying = underlying_;

        pid = pid_;
        token0 = token0_;
        token1 = token1_;
        rewardToken0 = rewardToken0_;
        rewardToken1 = rewardToken1_;
    }

    // --------------- Views ---------------

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

    // --------------- Actions ---------------

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

    // --------------- Internal ---------------

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
        if (reward0 > 0) {
            uint256 toToken0 = reward0 / 2;
            _swap(toToken0, rewardToken0, swapRoutes[rewardToken0][token0]);

            uint256 toToken1 = reward0 - toToken0;
            _swap(toToken1, rewardToken0, swapRoutes[rewardToken0][token1]);
        }

        uint256 reward1 = IERC20(rewardToken1).balanceOf(address(this));
        if (reward1 > 0) {
            uint256 toToken0 = reward1 / 2;
            _swap(toToken0, rewardToken1, swapRoutes[rewardToken1][token0]);

            uint256 toToken1 = reward1 - toToken0;
            _swap(toToken1, rewardToken1, swapRoutes[rewardToken1][token1]);
        }

        _provideLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }
}
