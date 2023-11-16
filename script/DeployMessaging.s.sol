// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Messaging} from "../src/Messaging.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DeployMessing is Script {
    address payable public proxyAddress;
    address public ImplementationAddress;
    Messaging public messaging;

    uint32[] public sourceChainIds;
    address[] public lightClients;
    address[] public broadcasters;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        messaging = new Messaging();
        ImplementationAddress = address(messaging);
        bytes memory data = abi.encodeCall(
            messaging.initialize,
            (
                sourceChainIds,
                lightClients,
                broadcasters,
                vm.envAddress("timelock"),
                vm.envAddress("guardian"),
                vm.envBool("sendingEnabled")
            )
        );
        proxyAddress = payable(address(new ERC1967Proxy(ImplementationAddress, data)));
        vm.stopBroadcast();
    }
}

contract UpgradeMessing is Script {
    address public proxyAddress;
    address public ImplementationAddress;
    Messaging public messaging;

    error InvalidAddress(string reason);

    function run() external {
        proxyAddress = vm.envAddress("proxyAddress");
        if (proxyAddress == address(0)) {
            revert InvalidAddress("proxy address can not be zero");
        }

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        messaging = new Messaging();
        ImplementationAddress = address(messaging);
        UUPSUpgradeable proxy = UUPSUpgradeable(proxyAddress);
        proxy.upgradeTo(address(ImplementationAddress));

        vm.stopBroadcast();
    }
}
