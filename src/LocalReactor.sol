pragma solidity ^0.8.0;

import {ReactorEvents} from "@uniswap/uniswapx/base/ReactorEvents.sol";
import {ExclusiveDutchOrder, ExclusiveDutchOrderLib} from "@uniswap/uniswapx/lib/ExclusiveDutchOrderLib.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IMailbox} from "@hyperlane/contracts/interfaces/IMailbox.sol";
import {Message} from "@hyperlane/contracts/libs/Message.sol";
import {TypeCasts} from "@hyperlane/contracts/libs/TypeCasts.sol";
import {ResolvedOrder, OutputToken, SignedOrder,OrderInfo} from "@uniswap/uniswapx/base/ReactorStructs.sol";
import {ExclusivityOverrideLib} from "@uniswap/uniswapx/lib/ExclusivityOverrideLib.sol";
import {Permit2Lib} from "@uniswap/uniswapx/lib/Permit2Lib.sol";
import {DutchDecayLib} from "@uniswap/uniswapx/lib/DutchDecayLib.sol";
import {ExclusiveDutchOrderLib, ExclusiveDutchOrder, DutchOutput, DutchInput} from "@uniswap/uniswapx/lib/ExclusiveDutchOrderLib.sol";
   

contract LocalReactor is ReactorEvents {
    using Message for bytes;
    using ExclusiveDutchOrderLib for ExclusiveDutchOrder;

    using Permit2Lib for ResolvedOrder;
    using ExclusiveDutchOrderLib for ExclusiveDutchOrder;
    using DutchDecayLib for DutchOutput[];
    using DutchDecayLib for DutchInput;
    using ExclusivityOverrideLib for ResolvedOrder;

    IMailbox public immutable MAILBOX;

    constructor(address _mailbox) {
        MAILBOX = IMailbox(_mailbox);
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external {
        require(msg.sender == address(MAILBOX), "!mailbox");
        // todo: require _message.sender() == executor

        // todo: transfer input tokens

        ResolvedOrder memory order = abi.decode(_body, (ResolvedOrder));
        emit Fill(order.hash, TypeCasts.bytes32ToAddress(_sender), order.info.swapper, order.info.nonce);
    }


    // TODO: add OptimismISM
}
