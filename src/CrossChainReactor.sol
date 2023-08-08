pragma solidity ^0.8.0;

import {ReactorEvents} from "@uniswap/uniswapx/base/ReactorEvents.sol";
import {LimitOrder, LimitOrderLib} from "@uniswap/uniswapx/lib/LimitOrderLib.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IMailbox} from "@hyperlane/contracts/interfaces/IMailbox.sol";
import {Message} from "@hyperlane/contracts/libs/Message.sol";
import {TypeCasts} from "@hyperlane/contracts/libs/TypeCasts.sol";

contract CrossChainReactor is ReactorEvents {
    using Message for bytes;
    using LimitOrderLib for LimitOrder;

    IMailbox public immutable MAILBOX;

    constructor(address _mailbox) {
        MAILBOX = IMailbox(_mailbox);
    }

    function handle(bytes calldata _message, bytes calldata _metadata) external {
        require(msg.sender == address(MAILBOX), "!mailbox");
        // todo: require _message.sender() == executor

        LimitOrder memory order = abi.decode(_message, (LimitOrder));

        emit Fill(order.hash(), TypeCasts.bytes32ToAddress(_message.sender()), order.info.swapper, order.info.nonce);
    }

    // TODO: add OptimismISM
}
