// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVotingEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;
}
