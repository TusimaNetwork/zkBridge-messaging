// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import {Sender} from "src/Sender.sol";
import {Messaging} from "src/Messaging.sol";
import {UUPSProxy} from "src/libraries/Proxy.sol";
import {Bytes32} from "src/libraries/Typecast.sol";
import {MessageEncoding} from "src/libraries/MessageEncoding.sol";
import {WrappedInitialize} from "./libraries/WrappedInitialize.sol";

contract SenderTest is Test {
    event SendMsg(uint64 indexed nonce, bytes32 indexed msgHash, bytes message);

    uint32 constant DEFAULT_DESTINATION_CHAIN_ID = 100;
    address constant DEFAULT_DESTINATION_ADDR =
        0x690B9A9E9aa1C9dB991C7721a92d351Db4FaC990;
    bytes32 constant DEFAULT_DESTINATION_ADDR_BYTES32 =
        bytes32("0x690B9A9E9aa1C9dB991C7721a92d35");
    bytes constant DEFAULT_DESTINATION_DATA = hex"deadbeef";

    Messaging wrappedSourceProxy;

    address bob = payable(makeAddr("bob"));

    function setUp() public {
        Messaging sourceImplementation = new Messaging();
        UUPSProxy proxy = new UUPSProxy(address(sourceImplementation), "");

        wrappedSourceProxy = Messaging(address(proxy));
        WrappedInitialize.init(
            address(wrappedSourceProxy),
            uint32(block.chainid),
            makeAddr("lightclient"),
            makeAddr("source"),
            address(this),
            address(this)
        );
    }

    function test_Send_WhenAddressDestination() public {
        vm.startPrank(bob);
        bytes memory expectedMessage = MessageEncoding.encode(
            wrappedSourceProxy.VERSION(),
            Sender(wrappedSourceProxy).nonce(),
            uint32(block.chainid),
            bob,
            DEFAULT_DESTINATION_CHAIN_ID,
            Bytes32.fromAddress(DEFAULT_DESTINATION_ADDR),
            DEFAULT_DESTINATION_DATA
        );
        bytes32 expectedMessageRoot = keccak256(expectedMessage);

        vm.expectEmit(true, true, true, true);
        emit SendMsg(
            Sender(wrappedSourceProxy).nonce(),
            expectedMessageRoot,
            expectedMessage
        );

        bytes32 messageRoot = wrappedSourceProxy.send(
            DEFAULT_DESTINATION_CHAIN_ID,
            DEFAULT_DESTINATION_ADDR,
            DEFAULT_DESTINATION_DATA
        );
        assertEq(messageRoot, expectedMessageRoot);
    }

    function testFuzz_Send_MsgSender(address sender) public {
        vm.startPrank(sender);
        bytes memory expectedMessage = MessageEncoding.encode(
            wrappedSourceProxy.VERSION(),
            Sender(wrappedSourceProxy).nonce(),
            uint32(block.chainid),
            sender,
            DEFAULT_DESTINATION_CHAIN_ID,
            Bytes32.fromAddress(DEFAULT_DESTINATION_ADDR),
            DEFAULT_DESTINATION_DATA
        );
        bytes32 expectedMessageRoot = keccak256(expectedMessage);

        vm.expectEmit(true, true, true, true);
        emit SendMsg(
            Sender(wrappedSourceProxy).nonce(),
            expectedMessageRoot,
            expectedMessage
        );

        bytes32 messageRoot = wrappedSourceProxy.send(
            DEFAULT_DESTINATION_CHAIN_ID,
            DEFAULT_DESTINATION_ADDR,
            DEFAULT_DESTINATION_DATA
        );
        assertEq(messageRoot, expectedMessageRoot);
    }

    function testFuzz_Send_DestinationChainId(uint32 _chainId) public {
        vm.assume(_chainId != block.chainid);

        vm.startPrank(bob);
        bytes memory expectedMessage = MessageEncoding.encode(
            wrappedSourceProxy.VERSION(),
            Sender(wrappedSourceProxy).nonce(),
            uint32(block.chainid),
            bob,
            _chainId,
            Bytes32.fromAddress(DEFAULT_DESTINATION_ADDR),
            DEFAULT_DESTINATION_DATA
        );
        bytes32 expectedMessageRoot = keccak256(expectedMessage);

        vm.expectEmit(true, true, true, true);
        emit SendMsg(
            Sender(wrappedSourceProxy).nonce(),
            expectedMessageRoot,
            expectedMessage
        );

        bytes32 messageRoot = wrappedSourceProxy.send(
            _chainId,
            DEFAULT_DESTINATION_ADDR,
            DEFAULT_DESTINATION_DATA
        );
        assertEq(messageRoot, expectedMessageRoot);
    }

    function testFuzz_Send_DestinationAddress(
        address _destinationAddress
    ) public {
        vm.startPrank(bob);
        bytes memory expectedMessage = MessageEncoding.encode(
            wrappedSourceProxy.VERSION(),
            Sender(wrappedSourceProxy).nonce(),
            uint32(block.chainid),
            bob,
            DEFAULT_DESTINATION_CHAIN_ID,
            Bytes32.fromAddress(_destinationAddress),
            DEFAULT_DESTINATION_DATA
        );
        bytes32 expectedMessageRoot = keccak256(expectedMessage);

        vm.expectEmit(true, true, true, true);
        emit SendMsg(
            Sender(wrappedSourceProxy).nonce(),
            expectedMessageRoot,
            expectedMessage
        );

        bytes32 messageRoot = wrappedSourceProxy.send(
            DEFAULT_DESTINATION_CHAIN_ID,
            _destinationAddress,
            DEFAULT_DESTINATION_DATA
        );
        assertEq(messageRoot, expectedMessageRoot);
    }

    function testFuzz_Send_Data(bytes calldata _data) public {
        vm.startPrank(bob);
        bytes memory expectedMessage = MessageEncoding.encode(
            wrappedSourceProxy.VERSION(),
            Sender(wrappedSourceProxy).nonce(),
            uint32(block.chainid),
            bob,
            DEFAULT_DESTINATION_CHAIN_ID,
            Bytes32.fromAddress(DEFAULT_DESTINATION_ADDR),
            _data
        );
        bytes32 expectedMessageRoot = keccak256(expectedMessage);

        vm.expectEmit(true, true, true, true);
        emit SendMsg(
            Sender(wrappedSourceProxy).nonce(),
            expectedMessageRoot,
            expectedMessage
        );

        bytes32 messageRoot = wrappedSourceProxy.send(
            DEFAULT_DESTINATION_CHAIN_ID,
            DEFAULT_DESTINATION_ADDR,
            _data
        );
        assertEq(messageRoot, expectedMessageRoot);
    }
}
