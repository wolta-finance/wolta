//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperTokenFactory} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import {INativeSuperToken, NativeSuperTokenProxy} from "./NativeSuperToken.sol";
import {PolygonAaveLeveragedBorrowing_DAI_Vault} from "./strategies/polygon/aave/PolygonAaveLeveragedBorrowing_DAI.sol";

contract MasterStreamer {
    ISuperfluid private host; // host
    IConstantFlowAgreementV1 private cfa; // the stored constant flow agreement class address
    ISuperToken private acceptedToken; // accepted token
    INativeSuperToken public sybToken;
    ISuperTokenFactory private superTokenFactory;
    address public superVault;
    address public unwrappedAcceptedToken;
    uint256 constant TOTAL_SUPPLY = 1000000000000000000000000; // should be 0

    constructor(
        ISuperfluid host_,
        IConstantFlowAgreementV1 cfa_,
        ISuperToken acceptedToken_,
        ISuperTokenFactory superTokenFactory_,
        address controller_
    ) {
        host = host_;
        cfa = cfa_;
        acceptedToken = acceptedToken_;
        superTokenFactory = superTokenFactory_;

        // deploy the custom super token proxy
        sybToken = INativeSuperToken(address(new NativeSuperTokenProxy()));

        // get the underlying token
        // unwrappedAcceptedToken = address(
        //     ISuperToken(acceptedToken).getUnderlyingToken()
        // );

        // deploy the superVault using the new sybToken address
        superVault = address(
            new PolygonAaveLeveragedBorrowing_DAI_Vault(
                host,
                cfa,
                acceptedToken,
                ISuperToken(address(sybToken)),
                controller_
                // unwrappedAcceptedToken
            )
        );

        // Set the proxy to use the Super Token logic managed by Superfluid Protocol Governance
        superTokenFactory.initializeCustomSuperToken(address(sybToken));

        // Set up the token and start with 0 tokens in the super vault
        // string(abi.encodePacked("TBD ", ERC20(underlying_).name())),
        // string(abi.encodePacked("t", ERC20(underlying_).symbol())),
        // ERC20(underlying_).decimals()
        sybToken.initialize(
            "streamed yield bearing TBD",
            "sybTBD",
            TOTAL_SUPPLY,
            address(superVault)
        );
    }
}
