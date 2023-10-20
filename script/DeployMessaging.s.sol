// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Messaging} from "../src/Messaging.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMessing is Script {
    address public proxyAddress;
    address public ImplementationAddress;
    Messaging public messaging;

    uint32[] public sourceChainIds;
    address[] public lightClients;
    address[] public broadcasters;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        messaging = new Messaging();
        ImplementationAddress = address(messaging);
        bytes memory data = abi.encodeCall(messaging.initialize, (
            sourceChainIds,
            lightClients,
            broadcasters,
            vm.envAddress("timelock"),
            vm.envAddress("guardian"),
            vm.envBool("sendingEnabled")
        ));
        proxyAddress = address(new ERC1967Proxy(ImplementationAddress, data));
        vm.stopBroadcast();
    }
}