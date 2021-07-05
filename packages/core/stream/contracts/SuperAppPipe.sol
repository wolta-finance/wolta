// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "./interfaces/IController.sol";

import "./utils/ERC20WithDecimals.sol";

contract SuperAppPipe is IERC777Recipient, SuperAppBase {
    ISuperfluid private host; // host
    IConstantFlowAgreementV1 private cfa; // the stored constant flow agreement class address
    ISuperToken private acceptedToken; // accepted inflow token
    ISuperToken private yBearingToken; // outflow token to customer

    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    constructor(
        ISuperfluid host_,
        IConstantFlowAgreementV1 cfa_,
        ISuperToken acceptedToken_,
        ISuperToken yBearingToken_
    ) {
        require(address(host_) != address(0), "host is zero address");
        require(address(cfa_) != address(0), "cfa is zero address");
        require(
            address(acceptedToken_) != address(0),
            "acceptedToken is zero address"
        );
        require(
            address(yBearingToken_) != address(0),
            "yBearingToken is zero address"
        );

        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        host = host_;
        cfa = cfa_;
        acceptedToken = acceptedToken_;
        yBearingToken = yBearingToken_;
        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        host.registerApp(configWord);
    }

    /**************************************************************************
     * SuperAppPipe Logic
     *************************************************************************/

    /// @dev If a new stream is opened, or an existing one is opened
    function _updateOutflow(
        bytes calldata ctx,
        address customer,
        bytes32 agreementId
    ) private returns (bytes memory newCtx) {
        newCtx = ctx;
        (, int96 inFlowRate, , ) = cfa.getFlowByID(acceptedToken, agreementId);
        (, int96 outFlowRate, , ) = cfa.getFlow(
            yBearingToken,
            address(this),
            customer
        );
        if (inFlowRate < 0) inFlowRate = -inFlowRate; // Fixes issue when inFlowRate is negative

        if (outFlowRate != int96(0)) {
            // @dev if there already exists an outflow, then update it.
            (newCtx, ) = host.callAgreementWithContext(
                cfa,
                abi.encodeWithSelector(
                    cfa.updateFlow.selector,
                    yBearingToken,
                    customer,
                    inFlowRate,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        } else if (inFlowRate == int96(0)) {
            // @dev if inFlowRate is zero, delete outflow.
            (newCtx, ) = host.callAgreementWithContext(
                cfa,
                abi.encodeWithSelector(
                    cfa.deleteFlow.selector,
                    yBearingToken,
                    address(this),
                    customer,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        } else {
            // @dev If there is no existing outflow, then create new flow to equal inflow
            (newCtx, ) = host.callAgreementWithContext(
                cfa,
                abi.encodeWithSelector(
                    cfa.createFlow.selector,
                    yBearingToken,
                    customer,
                    inFlowRate,
                    new bytes(0) // placeholder
                ),
                "0x",
                newCtx
            );
        }
    }

    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/
    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        address customer = host.decodeCtx(_ctx).msgSender;
        return _updateOutflow(_ctx, customer, _agreementId);
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        address customer = host.decodeCtx(_ctx).msgSender;
        return _updateOutflow(_ctx, customer, _agreementId);
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 _agreementId,
        bytes calldata _agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        if (!_isSameToken(_superToken) || !_isCFAv1(_agreementClass))
            return _ctx;
        (address customer, ) = abi.decode(_agreementData, (address, address));
        return _updateOutflow(_ctx, customer, _agreementId);
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external view override {
        require(
            msg.sender == address(acceptedToken),
            "Simple777Recipient: Invalid token"
        );
    }

    function getNetFlow() public view returns (int96) {
        return cfa.getNetFlow(acceptedToken, address(this));
    }

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(acceptedToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return
            ISuperAgreement(agreementClass).agreementType() ==
            keccak256(
                "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
            );
    }

    modifier onlyHost() {
        require(
            msg.sender == address(host),
            "SuperAppRouter: support only one host"
        );
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "SuperAppRouter: not accepted token");
        require(
            _isCFAv1(agreementClass),
            "SuperAppRouter: only CFAv1 supported"
        );
        _;
    }
}
