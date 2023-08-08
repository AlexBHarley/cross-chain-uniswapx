pragma solidity ^0.8.0;

import {ReactorEvents} from "@uniswap/uniswapx/base/ReactorEvents.sol";
import {LimitOrder, LimitOrderLib} from "@uniswap/uniswapx/lib/LimitOrderLib.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IMailbox} from "@hyperlane/contracts/interfaces/IMailbox.sol";
import {Message} from "@hyperlane/contracts/libs/Message.sol";
import {TypeCasts} from "@hyperlane/contracts/libs/TypeCasts.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";
import {ResolvedOrder, OutputToken, SignedOrder} from "@uniswap/uniswapx/base/ReactorStructs.sol";

contract CrossChainExecutor is Ownable, Initializable {
    using Message for bytes;
    using LimitOrderLib for LimitOrder;

    mapping(bytes32 => bool) public fills;

    IMailbox public immutable MAILBOX;
    address public REACTOR;

    constructor(address _mailbox) Ownable() {
        MAILBOX = IMailbox(_mailbox);
    }

    function initialize(address _reactor) public initializer {
        REACTOR = _reactor;
    }

    function execute(SignedOrder calldata _order, bytes calldata callbackData) external onlyOwner {
        LimitOrder memory order = abi.decode(_order.order, (LimitOrder));

        MAILBOX.dispatch(
            uint32(420),
            TypeCasts.addressToBytes32(REACTOR),
            _order.order
        );
    }
}
