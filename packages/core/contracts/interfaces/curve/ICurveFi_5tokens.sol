//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface ICurveFi_atricrypto {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        // atricrypto pool
        uint256[5] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[5] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[5] calldata amounts)
        external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function exchange_underlying(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function calc_token_amount(uint256[5] calldata amounts, bool deposit)
        external
        view
        returns (uint256);
}

interface Zap {
    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}
