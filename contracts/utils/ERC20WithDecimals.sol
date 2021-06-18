// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20WithDecimals is ERC20 {
    // --------------- Fields ---------------

    uint8 private _decimals;

    // --------------- Constructor ---------------

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    // --------------- Views ---------------

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
