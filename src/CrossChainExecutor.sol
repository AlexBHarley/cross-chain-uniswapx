pragma solidity ^0.8.0;

import {ReactorEvents} from "@uniswap/uniswapx/base/ReactorEvents.sol";
import {LimitOrder, LimitOrderLib} from "@uniswap/uniswapx/lib/LimitOrderLib.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IMailbox} from "@hyperlane/contracts/interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "@hyperlane/contracts/interfaces/IInterchainGasPaymaster.sol";
import {Message} from "@hyperlane/contracts/libs/Message.sol";
import {TypeCasts} from "@hyperlane/contracts/libs/TypeCasts.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";
import {ResolvedOrder, OutputToken, SignedOrder} from "@uniswap/uniswapx/base/ReactorStructs.sol";

import "forge-std/console.sol";

contract CrossChainExecutor is Ownable, Initializable {
    using Message for bytes;
    using LimitOrderLib for LimitOrder;

    IMailbox public immutable MAILBOX;
    IInterchainGasPaymaster public immutable IGP;
    address public REACTOR;

    mapping(bytes32 => bool) public fills;

    constructor(address _mailbox, address _igp) Ownable() {
        MAILBOX = IMailbox(_mailbox);
        IGP = IInterchainGasPaymaster(_igp);
    }

    function initialize(address _reactor) public 
    // initializer onlyOwner
    {
        REACTOR = _reactor;
    }

    function execute(SignedOrder calldata _order, bytes calldata callbackData) public payable 
    // onlyOwner
    {
        executeWithCallback(_order, callbackData);
    }

    function executeWithCallback(SignedOrder calldata _order, bytes calldata callbackData) public payable 
    // onlyOwner
    {
        LimitOrder memory order = abi.decode(_order.order, (LimitOrder));

        bytes32 messageId = MAILBOX.dispatch(uint32(420), TypeCasts.addressToBytes32(REACTOR), _order.order);
        IGP.payForGas{value: msg.value}(
            messageId,
            420, // The destination domain of the message
            100_000, // 100k gas to use in the recipient's handle function
            msg.sender // refunds go to msg.sender, who paid the msg.value
        );
    }
}
