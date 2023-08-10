// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ReactorEvents} from "@uniswap/uniswapx/base/ReactorEvents.sol";
import {ResolvedOrderLib} from "@uniswap/uniswapx/lib/ResolvedOrderLib.sol";
import {CurrencyLibrary, NATIVE} from "@uniswap/uniswapx/lib/CurrencyLibrary.sol";
import {IReactorCallback} from "@uniswap/uniswapx/interfaces/IReactorCallback.sol";
import {IReactor} from "@uniswap/uniswapx/interfaces/IReactor.sol";
import {ProtocolFees} from "@uniswap/uniswapx/base/ProtocolFees.sol";
import {SignedOrder, ResolvedOrder, OutputToken} from "@uniswap/uniswapx/base/ReactorStructs.sol";
import {IMailbox} from "@hyperlane/contracts/interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "@hyperlane/contracts/interfaces/IInterchainGasPaymaster.sol";
import {Message} from "@hyperlane/contracts/libs/Message.sol";
import {TypeCasts} from "@hyperlane/contracts/libs/TypeCasts.sol";


/// @notice Generic reactor logic for settling off-chain signed orders
///     using arbitrary fill methods specified by a filler
abstract contract BaseReactor is IReactor, ReactorEvents, ProtocolFees, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using ResolvedOrderLib for ResolvedOrder;
    using CurrencyLibrary for address;

    // Occurs when an output = ETH and the reactor does contain enough ETH but
    // the direct filler did not include enough ETH in their call to execute/executeBatch
    error InsufficientEth();

    /// @notice permit2 address used for token transfers and signature verification
    IPermit2 public immutable permit2;
    IMailbox public immutable MAILBOX;
    IInterchainGasPaymaster public immutable IGP;
    address public REACTOR;

    constructor(address _mailbox, address _igp, IPermit2 _permit2, address _protocolFeeOwner) ProtocolFees(_protocolFeeOwner) {
        permit2 = _permit2;
        MAILBOX = IMailbox(_mailbox);
        IGP = IInterchainGasPaymaster(_igp);
    }

    function setReactor(address _reactor) public onlyOwner
    {
        REACTOR = _reactor;
    }

    /// @inheritdoc IReactor
    function execute(SignedOrder calldata order) external payable override nonReentrant {
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](1);
        resolvedOrders[0] = resolve(order);

        // _prepare(resolvedOrders);
        _fill(resolvedOrders);
    }

    /// @inheritdoc IReactor
    function executeWithCallback(SignedOrder calldata order, bytes calldata callbackData)
        external
        payable
        override
        nonReentrant
    {
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](1);
        resolvedOrders[0] = resolve(order);

        // _prepare(resolvedOrders);
        IReactorCallback(msg.sender).reactorCallback(resolvedOrders, callbackData);
        _fill(resolvedOrders);
    }

    /// @inheritdoc IReactor
    function executeBatch(SignedOrder[] calldata orders) external payable override nonReentrant {
        uint256 ordersLength = orders.length;
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](ordersLength);

        unchecked {
            for (uint256 i = 0; i < ordersLength; i++) {
                resolvedOrders[i] = resolve(orders[i]);
            }
        }

        // _prepare(resolvedOrders);
        _fill(resolvedOrders);
    }

    /// @inheritdoc IReactor
    function executeBatchWithCallback(SignedOrder[] calldata orders, bytes calldata callbackData)
        external
        payable
        override
        nonReentrant
    {
        uint256 ordersLength = orders.length;
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](ordersLength);

        unchecked {
            for (uint256 i = 0; i < ordersLength; i++) {
                resolvedOrders[i] = resolve(orders[i]);
            }
        }

        _prepare(resolvedOrders);
        IReactorCallback(msg.sender).reactorCallback(resolvedOrders, callbackData);
        _fill(resolvedOrders);
    }

    /// @notice validates, injects fees, and transfers input tokens in preparation for order fill
    /// @param orders The orders to prepare
    function _prepare(ResolvedOrder[] memory orders) internal {
        uint256 ordersLength = orders.length;
        unchecked {
            for (uint256 i = 0; i < ordersLength; i++) {
                ResolvedOrder memory order = orders[i];
                _injectFees(order);
                order.validate(msg.sender);
                // transferInputTokens(order, msg.sender);
            }
        }
    }

    /// @notice fills a list of orders, ensuring all outputs are satisfied
    /// @param orders The orders to fill
    function _fill(ResolvedOrder[] memory orders) internal {
        bytes32 messageId = MAILBOX.dispatch(uint32(420), TypeCasts.addressToBytes32(REACTOR), abi.encode(orders[0]));

        IGP.payForGas{value: msg.value}(
            messageId,
            420, // The destination domain of the message
            100_000, // 100k gas to use in the recipient's handle function
            msg.sender // refunds go to msg.sender, who paid the msg.value
        );
    }

    receive() external payable {
        // receive native asset to support native output
    }

    /// @notice Resolve order-type specific requirements into a generic order with the final inputs and outputs.
    /// @param order The encoded order to resolve
    /// @return resolvedOrder generic resolved order of inputs and outputs
    /// @dev should revert on any order-type-specific validation errors
    function resolve(SignedOrder calldata order) internal view virtual returns (ResolvedOrder memory resolvedOrder);
}
