// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {ExclusiveDutchOrderReactor} from "../src/ExclusiveDutchOrderReactor.sol";
import {LocalReactor} from "../src/LocalReactor.sol";

contract UniswapX is Script {
    function setUp() public {}

    function run() public {
        // https://docs.hyperlane.xyz/docs/resources/addresses#mailbox-1

        uint256 goerliFork = vm.createFork(vm.envString("RPC_URL_5"));
        vm.selectFork(goerliFork);
        vm.startBroadcast();
        ExclusiveDutchOrderReactor remoteReactor = new ExclusiveDutchOrderReactor(
            0xCC737a94FecaeC165AbCf12dED095BB13F037685, // Mailbox
            0xF90cB82a76492614D07B82a7658917f3aC811Ac1, // IGP
            IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3), // Permit2
            msg.sender // Owner
        );
        console2.log("RemoteReactor deployed to", address(remoteReactor));
        vm.stopBroadcast();

        uint256 opFork = vm.createSelectFork(vm.envString("RPC_URL_420"));
        // vm.selectFork(opFork);
        // vm.startBroadcast();
        // LocalReactor localReactor = new LocalReactor(0xCC737a94FecaeC165AbCf12dED095BB13F037685);
        // console2.log("LocalReactor deployed to", address(localReactor));
        // vm.stopBroadcast();

        vm.selectFork(goerliFork);
        vm.startBroadcast();
        // remoteReactor.setReactor(address(localReactor));
        remoteReactor.setReactor(0x86Eb5e059a62060a0dC35ebb5023a8AD09E1da45);
        vm.stopBroadcast();  

        vm.selectFork(opFork);
        vm.startBroadcast();
        // reactor.initialize(address(remoteReactor));
        vm.stopBroadcast();
    }
}
