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
        uint256 goerliFork = vm.createFork(vm.envString("RPC_URL_5"));
        vm.selectFork(goerliFork);
        vm.startBroadcast();
        CrossChainReactor reactor = new CrossChainReactor(0xCC737a94FecaeC165AbCf12dED095BB13F037685);
        console2.log("Reactor deployed to", address(reactor));
        // vm.makePersistent(address(reactor));
        vm.stopBroadcast();

        // Goerli
        uint256 opFork = vm.createSelectFork(vm.envString("RPC_URL_420"));
        vm.selectFork(opFork);
        vm.startBroadcast();
        CrossChainExecutor executor = new CrossChainExecutor(0xCC737a94FecaeC165AbCf12dED095BB13F037685);
        console2.log("Executor deployed to", address(executor));
        // vm.makePersistent(address(executor));
        vm.stopBroadcast();

        // Optimism
        vm.selectFork(goerliFork);
        vm.startBroadcast();
        // reactor.initialize(address(executor));
        vm.stopBroadcast();

        // Goerli
        vm.selectFork(opFork);
        vm.startBroadcast();
        executor.initialize(address(reactor));
        vm.stopBroadcast();
    }
}
