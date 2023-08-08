// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {CrossChainExecutor} from "../src/CrossChainExecutor.sol";
import {CrossChainReactor} from "../src/CrossChainReactor.sol";

contract UniswapX is Script {
    function setUp() public {}

    function run() public {
        // https://docs.hyperlane.xyz/docs/resources/addresses#mailbox-1

        // Optimism
        vm.createSelectFork(vm.envString("5_RPC_URL"));
        vm.startBroadcast();
        CrossChainReactor reactor = new CrossChainReactor(0xCC737a94FecaeC165AbCf12dED095BB13F037685);
        vm.stopBroadcast();

        // Goerli
        vm.createSelectFork(vm.envString("420_RPC_URL"));
        vm.startBroadcast();
        CrossChainExecutor executor = new CrossChainExecutor(0xCC737a94FecaeC165AbCf12dED095BB13F037685);
        vm.stopBroadcast();

        // Optimism
        // vm.createSelectFork(vm.envString("5_RPC_URL"));
        // vm.startBroadcast();
        // reactor.initialize(address(executor));
        // vm.stopBroadcast();

        // Goerli
        vm.createSelectFork(vm.envString("420_RPC_URL"));
        vm.startBroadcast();
        executor.initialize(address(reactor));
        vm.stopBroadcast();
    }
}
