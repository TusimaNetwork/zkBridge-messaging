// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import {Messaging} from "src/Messaging.sol";
import {UUPSProxy} from "src/libraries/Proxy.sol";
import {SSZ} from "src/libraries/SimpleSerialize.sol";
import {LightClientMock} from "./mock/LightClientMock.sol";
import {WrappedInitialize} from "./libraries/WrappedInitialize.sol";
import {MessageStatus, IReceiver} from "src/interfaces/IMessaging.sol";

// The weird ordering here is because vm.parseJSON requires
// alphabetaical ordering of the fields in the struct
struct ExecuteMessageFromStorageFixture {
    uint32 DEST_CHAIN;
    uint32 SOURCE_CHAIN;
    string[] accountProof;
    uint64 blockNumber;
    bytes message;
    address sourceSenderAddress;
    address sourceMessageSender;
    bytes32 stateRoot;
    string[] storageProof;
    bytes32 storageRoot;
}

struct ExecuteMessageFromStorageParams {
    uint32 DEST_CHAIN;
    uint32 SOURCE_CHAIN;
    bytes[] accountProof;
    uint64 blockNumber;
    bytes message;
    address sourceSenderAddress;
    address sourceMessageSender;
    bytes32 stateRoot;
    bytes[] storageProof;
    bytes32 storageRoot;
}

contract SimpleHandler is IReceiver {
    uint32 public sourceChain;
    address public sourceAddress;
    address public relayer;
    uint256 public nonce;
    mapping(uint256 => bytes32) public nonceToDataHash;

    function setParams(
        uint32 _sourceChain,
        address _sourceAddress,
        address _relayer
    ) public {
        sourceChain = _sourceChain;
        sourceAddress = _sourceAddress;
        relayer = _relayer;
    }

    function handleMsg(
        uint32 _sourceChainId,
        address _sourceAddress,
        bytes memory _data
    ) external override returns (bytes4) {
        require(msg.sender == relayer, "Only Messaging can call this function");
        require(_sourceChainId == sourceChain, "Invalid source chain id");
        require(_sourceAddress == sourceAddress, "Invalid source address");
        nonceToDataHash[nonce++] = keccak256(_data);
        return IReceiver.handleMsg.selector;
    }
}

contract RelayerTest is Test {
    LightClientMock lightClientMock;
    Messaging relayer;
    SimpleHandler simpleHandler;

    function setUp() public {
        lightClientMock = new LightClientMock();
    }

    function parseParams(
        string memory filename
    ) internal view returns (ExecuteMessageFromStorageParams memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/test/fixtures/",
            filename,
            ".json"
        );
        string memory file = vm.readFile(path);
        bytes memory parsed = vm.parseJson(file);
        ExecuteMessageFromStorageFixture memory fixture = abi.decode(
            parsed,
            (ExecuteMessageFromStorageFixture)
        );

        ExecuteMessageFromStorageParams memory params;
        params.DEST_CHAIN = fixture.DEST_CHAIN;
        params.SOURCE_CHAIN = fixture.SOURCE_CHAIN;
        params.accountProof = buildAccountProof(fixture);
        params.blockNumber = fixture.blockNumber;
        params.message = fixture.message;
        params.sourceSenderAddress = fixture.sourceSenderAddress;
        params.sourceMessageSender = fixture.sourceMessageSender;
        params.stateRoot = fixture.stateRoot;
        params.storageProof = buildStorageProof(fixture);
        params.storageRoot = fixture.storageRoot;

        return params;
    }

    function buildAccountProof(
        ExecuteMessageFromStorageFixture memory fixture
    ) internal pure returns (bytes[] memory) {
        bytes[] memory proof = new bytes[](8);
        proof[0] = vm.parseBytes(fixture.accountProof[0]);
        proof[1] = vm.parseBytes(fixture.accountProof[1]);
        proof[2] = vm.parseBytes(fixture.accountProof[2]);
        proof[3] = vm.parseBytes(fixture.accountProof[3]);
        proof[4] = vm.parseBytes(fixture.accountProof[4]);
        proof[5] = vm.parseBytes(fixture.accountProof[5]);
        proof[6] = vm.parseBytes(fixture.accountProof[6]);
        proof[7] = vm.parseBytes(fixture.accountProof[7]);
        return proof;
    }

    function buildStorageProof(
        ExecuteMessageFromStorageFixture memory fixture
    ) internal pure returns (bytes[] memory) {
        bytes[] memory proof = new bytes[](3);
        proof[0] = vm.parseBytes(fixture.storageProof[0]);
        proof[1] = vm.parseBytes(fixture.storageProof[1]);
        proof[2] = vm.parseBytes(fixture.storageProof[2]);
        return proof;
    }

    function getDefaultContractSetup(
        ExecuteMessageFromStorageParams memory messageParams
    ) internal {
        vm.chainId(messageParams.DEST_CHAIN);

        Messaging targetImplementation = new Messaging();

        UUPSProxy proxy = new UUPSProxy(address(targetImplementation), "");

        relayer = Messaging(address(proxy));
        WrappedInitialize.init(
            address(relayer),
            messageParams.SOURCE_CHAIN,
            address(lightClientMock),
            messageParams.sourceSenderAddress,
            address(this),
            address(this)
        );

        // Then initialize the contract that will be called by the Relayer
        SimpleHandler simpleHandlerTemplate = new SimpleHandler();
        vm.etch(address(0), address(simpleHandlerTemplate).code);
        simpleHandler = SimpleHandler(address(0));
        simpleHandler.setParams(
            messageParams.SOURCE_CHAIN,
            messageParams.sourceMessageSender,
            address(relayer)
        );

        // Then set the execution root in the LightClientMock
        // Typically we should use the slot here, but we just use the block number since it doesn't
        // matter in the LightClientMock
        vm.warp(
            messageParams.blockNumber -
                targetImplementation.MIN_LIGHT_CLIENT_DELAY()
        );
        lightClientMock.setExecutionRoot(
            messageParams.blockNumber,
            messageParams.stateRoot
        );
        vm.warp(messageParams.blockNumber);
    }

    function test_ExecuteMessage() public {
        // This test is generated using `cli/src/generateTest.ts`
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        // Finally, execute the message and check that it succeeded
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
        bytes32 messageRoot = keccak256(messageParams.message);
        assertTrue(
            relayer.messageStatus(messageRoot) ==
                MessageStatus.EXECUTION_SUCCEEDED
        );

        // Check that the simpleHandler processed the message correctly
        assertEq(simpleHandler.nonce(), 1);
        bytes32 expectedDataHash = keccak256(
            abi.encode(address(0), uint256(100))
        );
        assertEq(simpleHandler.nonceToDataHash(0), expectedDataHash);
    }

    function test_ExecuteMessage_WrongSourceAddressFails() public {
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        messageParams.sourceMessageSender = address(0x1234); // Set the source address to something random
        getDefaultContractSetup(messageParams);

        // Finally, execute the message and check that it failed
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
        bytes32 messageRoot = keccak256(messageParams.message);
        assertTrue(
            relayer.messageStatus(messageRoot) == MessageStatus.EXECUTION_FAILED
        );

        assertEq(simpleHandler.nonce(), 0);
    }

    function test_RevertExecuteMessage_WhenDuplicate() public {
        // Tests that a message can only be executed once.
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
        bytes32 messageRoot = keccak256(messageParams.message);
        assertTrue(
            relayer.messageStatus(messageRoot) ==
                MessageStatus.EXECUTION_SUCCEEDED
        );

        vm.expectRevert("Message already executed.");
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
    }

    function test_RevertExecuteMessage_WhenWrongSourceSenderAddress() public {
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        messageParams.sourceSenderAddress = address(0x1234); // Set the sourceSenderAddress to something incorrect
        getDefaultContractSetup(messageParams);

        vm.expectRevert();
        // The MPT verification should fail since the SourceAMB address provided is different than the one in the account proof
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
    }

    function test_ExecuteMessage_WrongTargetAMBFails() public {
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        address randomRelayer = address(0x1234);
        simpleHandler.setParams(
            simpleHandler.sourceChain(),
            simpleHandler.sourceAddress(),
            randomRelayer
        );

        // Finally, execute the message and check that it failed
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
        bytes32 messageRoot = keccak256(messageParams.message);
        assertTrue(
            relayer.messageStatus(messageRoot) == MessageStatus.EXECUTION_FAILED
        );

        assertEq(simpleHandler.nonce(), 0);
    }

    function test_RevertExecuteMessage_WhenInvalidDestination() public {
        // Test what happens when the destination address doesn't implement the ITelepathyHandler
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        // Set the simpleHandler code to random bytes
        bytes memory randomCode = hex"1234";
        vm.etch(address(0), randomCode);

        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
        // The message execution should fail
        bytes32 messageRoot = keccak256(messageParams.message);
        assertTrue(
            relayer.messageStatus(messageRoot) == MessageStatus.EXECUTION_FAILED
        );
    }

    function test_RevertExecuteMessage_WrongSrcChain() public {
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        messageParams.SOURCE_CHAIN = 6; // Set the source chain to something other than 5
        getDefaultContractSetup(messageParams);

        vm.expectRevert();
        // Finally, execute the message and check that it failed
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
    }

    /*

    function test_RevertExecuteMessage_WhenLightClientDelayNotPassed() public {
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        vm.warp(
            messageParams.blockNumber - relayer.MIN_LIGHT_CLIENT_DELAY() + 1
        );
        lightClientMock.setExecutionRoot(
            messageParams.blockNumber,
            messageParams.stateRoot
        );
        vm.warp(messageParams.blockNumber);

        vm.expectRevert();
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            messageParams.storageProof
        );
    }
    */

    function test_ExecuteMessage_WhenCached() public {
        ExecuteMessageFromStorageParams memory messageParams1 = parseParams(
            "storage1"
        );
        ExecuteMessageFromStorageParams memory messageParams2 = parseParams(
            "storage2"
        );
        ExecuteMessageFromStorageParams memory messageParams3 = parseParams(
            "storage3"
        );
        getDefaultContractSetup(messageParams1);

        bytes32 cacheKey1 = keccak256(
            abi.encodePacked(
                messageParams1.SOURCE_CHAIN,
                messageParams1.blockNumber,
                relayer.broadcasters(messageParams1.SOURCE_CHAIN)
            )
        );
        assertEq(relayer.storageRootCache(cacheKey1), bytes32(0));

        relayer.vMsg(
            messageParams1.blockNumber,
            messageParams1.message,
            messageParams1.accountProof,
            messageParams1.storageProof
        );

        bytes32 cacheKey2 = keccak256(
            abi.encodePacked(
                messageParams2.SOURCE_CHAIN,
                messageParams2.blockNumber,
                relayer.broadcasters(messageParams2.SOURCE_CHAIN)
            )
        );
        assertEq(
            relayer.storageRootCache(cacheKey2),
            messageParams1.storageRoot
        );

        relayer.vMsg(
            messageParams2.blockNumber,
            messageParams2.message,
            messageParams2.accountProof,
            messageParams2.storageProof
        );

        bytes32 cacheKey3 = keccak256(
            abi.encodePacked(
                messageParams3.SOURCE_CHAIN,
                messageParams3.blockNumber,
                relayer.broadcasters(messageParams3.SOURCE_CHAIN)
            )
        );
        assertEq(
            relayer.storageRootCache(cacheKey3),
            messageParams1.storageRoot
        );

        relayer.vMsg(
            messageParams3.blockNumber,
            messageParams3.message,
            messageParams3.accountProof,
            messageParams3.storageProof
        );
    }

    function testFuzz_RevertExecutionMessage_InvalidProof(
        bytes[] memory _randomProof
    ) public {
        // We fuzz test what happens when we provide invalid proofs.
        // We fuzz test what happens when we provide invalid messages.
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        vm.expectRevert();
        // Finally, execute the message and check that it failed
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            _randomProof,
            messageParams.storageProof
        );

        vm.expectRevert();
        // Finally, execute the message and check that it failed
        relayer.vMsg(
            messageParams.blockNumber,
            messageParams.message,
            messageParams.accountProof,
            _randomProof
        );
    }

    function testFuzz_RevertExecuteMessage_InvalidMessage(
        bytes memory _message
    ) public {
        // We fuzz test what happens when we provide invalid messages.
        ExecuteMessageFromStorageParams memory messageParams = parseParams(
            "storage1"
        );
        getDefaultContractSetup(messageParams);

        vm.expectRevert();
        // Finally, execute the message and check that it failed
        relayer.vMsg(
            messageParams.blockNumber,
            _message,
            messageParams.accountProof,
            messageParams.storageProof
        );
    }
}
