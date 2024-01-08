// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Messaging} from "../src/Messaging.sol";

contract DeployMessaging is Script {
    Messaging public messaging;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        messaging = new Messaging(vm.envBool("sendingEnabled"));

        messaging.setRelayer(vm.envAddress("broadcasters"), true);

        vm.stopBroadcast();
    }
}
