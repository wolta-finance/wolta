// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "./interfaces/IController.sol";

import "./Vault.sol";
import "./SuperAppPipe.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract SuperVault is Vault, SuperAppPipe {
    using SafeERC20 for IERC20;

    ISuperfluid private host; // host
    IConstantFlowAgreementV1 private cfa; // the stored constant flow agreement class address
    ISuperToken private acceptedToken; // accepted inflow token
    ISuperToken private yBearingToken; // outflow token to customer
    uint256 private _underlyingUnit;

    address unwrappedAcceptedToken; // ERC20 underlying token wrapped into ERC777

    constructor(
        ISuperfluid host_,
        IConstantFlowAgreementV1 cfa_,
        ISuperToken acceptedToken_,
        ISuperToken yBearingToken_,
        address controller_,
        address underlying_,
        uint256 investmentPercentage_
    )
        SuperAppPipe(host_, cfa_, acceptedToken_, yBearingToken_)
        Vault(controller_, underlying_, investmentPercentage_)
    {
        _underlyingUnit = 10**uint256(ISuperToken(yBearingToken_).decimals());
        unwrappedAcceptedToken = underlying_;
    }

    function pricePerShare() public view returns (uint256) {
        if (ISuperToken(yBearingToken).totalSupply() == 0) {
            return _underlyingUnit;
        }
        return
            (_underlyingUnit * totalUnderlyingBalance()) /
            ISuperToken(yBearingToken).totalSupply();
    }

    function withdraw(
        uint256 shares,
        address to,
        bytes calldata userData
    ) public whenStrategyDefined {
        require(shares > 0, "Cannot withdraw zero");
        require(to != address(0), "Recipient cannot be address zero");

        uint256 sharesTotalSupply = ISuperToken(yBearingToken).totalSupply();
        ISuperToken(yBearingToken).burn(shares, userData); // SHOULD TEST THIS --> SuperVault is operator for contract caller and the tokens should be burned from the caller's account

        uint256 amountToWithdraw = (totalUnderlyingBalance() * shares) /
            sharesTotalSupply;
        if (amountToWithdraw > underlyingBalanceInVault()) {
            IStrategy(strategy).withdraw(
                amountToWithdraw - underlyingBalanceInVault()
            );
        }
        // ISuperToken(underlying).upgrade(amountToWithdraw);
        IERC20(underlying).safeTransfer(to, amountToWithdraw);
    }

    function availableToDowngrade() public view returns (uint256) {
        return ISuperToken(acceptedToken).balanceOf(address(this));
    }

    function downgradeFunds(uint256 amount) public onlyControllerOrGovernance {
        ISuperToken(acceptedToken).downgrade(amount);
    }

    function availableToTransfer() public view returns (uint256) {
        return IERC20(unwrappedAcceptedToken).balanceOf(address(this));
    }
}
