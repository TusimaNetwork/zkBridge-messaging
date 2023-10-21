// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import {WrappedInitialize} from "./libraries/WrappedInitialize.sol";
import {Timelock} from "src/libraries/Timelock.sol";
import {Messaging} from "src/Messaging.sol";
import {UUPSProxy} from "src/libraries/Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MessagingTest is Test {
    function test_InitializeImplementation() public {
        Messaging router = new Messaging();
        uint32[] memory sourceChainIds = new uint32[](1);
        sourceChainIds[0] = 1;
        address[] memory lightClients = new address[](1);
        lightClients[0] = address(this);
        address[] memory broadcasters = new address[](1);
        broadcasters[0] = address(this);

        vm.expectRevert();
        router.initialize(
            sourceChainIds,
            lightClients,
            broadcasters,
            address(this),
            address(this),
            true
        );
    }

    function test_InitializeProxy() public {
        Messaging implementation = new Messaging();
        UUPSProxy proxy = new UUPSProxy(address(implementation), "");

        uint32[] memory sourceChainIds = new uint32[](1);
        sourceChainIds[0] = 1;
        address[] memory lightClients = new address[](1);
        lightClients[0] = address(this);
        address[] memory broadcasters = new address[](1);
        broadcasters[0] = address(this);

        Messaging(address(proxy)).initialize(
            sourceChainIds,
            lightClients,
            broadcasters,
            address(this),
            address(this),
            true
        );
    }
}

contract MessagingUpgradeableTest is Test {
    UUPSProxy proxy;
    Messaging RouterProxy;
    Timelock timelock;

    address bob = payable(makeAddr("bob"));
    bytes32 SALT =
        0x025e7b0be353a74631ad648c667493c0e1cd31caa4cc2d3520fdc171ea0cc726;
    uint256 MIN_DELAY = 60 * 24 * 24;

    function setUp() public {
        Messaging router = new Messaging();
        proxy = new UUPSProxy(address(router), "");
        setUpTimelock();

        RouterProxy = Messaging(address(proxy));

        WrappedInitialize.init(
            address(RouterProxy),
            uint32(block.chainid),
            makeAddr("lightclient"),
            makeAddr("sourceAMB"),
            address(timelock),
            address(this)
        );
    }

    function setUpTimelock() public {
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = bob;
        executors[0] = bob;

        timelock = new Timelock(MIN_DELAY, proposers, executors, address(0));
    }
}
