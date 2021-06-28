
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4

interface ICurveLiquidityRewardGauge {
    // Add functions for reward tokens

    function rewarded_token() external view returns (address);

    function rewards_for(address arg0) external view returns (uint256);
}