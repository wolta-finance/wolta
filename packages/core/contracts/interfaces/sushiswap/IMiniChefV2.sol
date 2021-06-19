// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMiniChefV2 {
    function lpToken(uint256 pid) external view returns (address);

    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256, int256);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;
}
