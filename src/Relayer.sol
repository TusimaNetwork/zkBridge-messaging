// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {StorageProof} from "./libraries/StateProofHelper.sol";
import {Address} from "./libraries/Typecast.sol";
import {MessageEncoding} from "./libraries/MessageEncoding.sol";

import {MessagingStorage} from "./MessagingStorage.sol";
import {IReceiver, IRelayer, Message, MessageStatus} from "zkBridge-messaging-interfaces/src/interfaces/IMessaging.sol";

import {IZkSync, L2Message} from "./interfaces/IZkSync.sol";

import {IScroll} from "./interfaces/IScrollInterface.sol";
import {IScrollMessenger, L2MessageProof, IL1ScrollMessenger} from "./interfaces/IScrollMessenger.sol";

/// @title Relayer contract
/// @notice Relay messages from source chain to current chain.
contract Relayer is MessagingStorage, ReentrancyGuard, IRelayer, IScroll {
    /// @notice The minimum delay for using any information from the light client.
    uint256 public constant MIN_LIGHT_CLIENT_DELAY = 2 minutes;

    /// @notice The index of the `messages` mapping.
    /// @dev We need this when calling `executeMessage` via storage proofs, as it is used in
    /// getting the slot key.
    uint256 internal constant MESSAGES_MAPPING_STORAGE_INDEX = 1;

    event PassMsg(
        uint32 indexed sourceChainId,
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message,
        bool status
    );

    /// @notice Gets the length of the sourceChainIds array.
    /// @return The length of the sourceChainIds array.
    function sourceChainIdsLength() external view returns (uint256) {
        return sourceChainIds.length;
    }

    // ethereum --> anywhere, debug version
    function vMsg(
        uint64 slot,
        bytes calldata messageBytes,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external override nonReentrant {
        (Message memory message, bytes32 messageRoot) = _checkPreconditions(
            messageBytes
        );
        // requireLightClientConsistency(message.sourceChainId);
        requireNotFrozen(message.sourceChainId);

        {
            // requireLightClientDelay(slot, message.sourceChainId);

            bytes32 storageRoot;
            bytes32 cacheKey = keccak256(
                abi.encodePacked(
                    message.sourceChainId,
                    slot,
                    broadcasters[message.sourceChainId]
                )
            );

            // If the cache is empty for the cacheKey, then we get the
            // storageRoot using the provided accountProof.
            if (storageRootCache[cacheKey] == 0) {
                bytes32 executionStateRoot = lightClients[message.sourceChainId]
                    .executionStateRoot(slot);
                require(
                    executionStateRoot != 0,
                    "Execution State Root is not set"
                );
                storageRoot = StorageProof.getStorageRoot(
                    accountProof,
                    broadcasters[message.sourceChainId],
                    executionStateRoot
                );
                storageRootCache[cacheKey] = storageRoot;
            } else {
                storageRoot = storageRootCache[cacheKey];
            }

            bytes32 slotKey = keccak256(
                abi.encode(
                    keccak256(
                        abi.encode(
                            message.nonce,
                            MESSAGES_MAPPING_STORAGE_INDEX
                        )
                    )
                )
            );
            uint256 slotValue = StorageProof.getStorageValue(
                slotKey,
                storageRoot,
                storageProof
            );

            if (bytes32(slotValue) != messageRoot) {
                revert("Invalid message hash.");
            }
        }

        _executeMessage(message, messageRoot, messageBytes);
    }

    // layer 1 --> zkSync
    function vMsgZkSyncL1ToL2(
        bytes calldata messageBytes
    ) external override nonReentrant {
        require(msgRelayer[msg.sender], "Wrong Sender!");
        (Message memory message, bytes32 messageRoot) = _checkPreconditions(
            messageBytes
        );

        _executeMessage(message, messageRoot, messageBytes);
    }

    // zkSync --> layer 1
    function vMsgZkSyncL2ToL1(
        address someSender,
        // zkSync block number in which the message was sent
        uint256 l1BatchNumber,
        // Message index, that can be received via API
        uint256 proofId,
        // The tx number in block
        uint16 trxIndex,
        // The message that was sent from l2
        bytes calldata messageBytes,
        // Merkle proof for the message
        bytes32[] calldata proof
    ) external override nonReentrant {
        require(msgRelayer[msg.sender], "Wrong Sender!");
        (Message memory message, bytes32 messageRoot) = _checkPreconditions(
            messageBytes
        );

        IZkSync zksync = IZkSync(zkSyncAddress);
        L2Message memory l2Message = L2Message({
            txNumberInBlock: trxIndex,
            sender: someSender,
            data: messageBytes
        });

        bool success = zksync.proveL2MessageInclusion(
            l1BatchNumber,
            proofId,
            l2Message,
            proof
        );

        require(success, "Failed to prove message inclusion");

        _executeMessage(message, messageRoot, messageBytes);
    }

    // scroll --> layer 1 to l2
    function vMsgScrollL1ToL2(
        bytes calldata messageBytes
    ) external override nonReentrant {
        require(msgRelayer[msg.sender], "Wrong Sender!");
        (Message memory message, bytes32 messageRoot) = _checkPreconditions(
            messageBytes
        );

        _executeMessage(message, messageRoot, messageBytes);
    }

    // scroll --> layer 2 to l1
    function vMsgScrollL2ToL1(
        uint256 nonce,
        uint256 batchIndex,
        bytes calldata proof,
        bytes calldata messageBytes
    ) external override nonReentrant {
        require(msgRelayer[msg.sender], "Wrong Sender!");
        (Message memory message, bytes32 messageRoot) = _checkPreconditions(
            messageBytes
        );

        IL1ScrollMessenger scrollMessenger = IL1ScrollMessenger(
            scrollL1Messager
        );
        scrollMessenger.relayMessageWithProof(
            broadcasters[message.sourceChainId],
            address(this),
            0,
            nonce,
            messageBytes,
            L2MessageProof(batchIndex, proof)
        );

        _executeMessage(message, messageRoot, messageBytes);
    }

    /// @notice Executes a message and updates storage with status and emits an event.
    /// @dev Assumes that the message is valid and has not been already executed.
    /// @dev Assumes that message, messageRoot and messageBytes have already been validated.
    /// @param message The message we want to execute.
    /// @param messageRoot The message root of the message.
    /// @param messageBytes The message we want to execute provided as bytes for use in the event.
    function _executeMessage(
        Message memory message,
        bytes32 messageRoot,
        bytes memory messageBytes
    ) internal {
        bool status;
        bytes memory data;
        {
            bytes memory receiveCall = abi.encodeWithSelector(
                IReceiver.handleMsg.selector,
                message.sourceChainId,
                message.sourceAddress,
                message.data
            );
            address destination = Address.fromBytes32(
                message.destinationAddress
            );
            (status, data) = destination.call(receiveCall);
        }

        // Unfortunately, there are some edge cases where a call may have a successful status but
        // not have actually called the handler. Thus, we enforce that the handler must return
        // a magic constant that we can check here. To avoid stack underflow / decoding errors, we
        // only decode the returned bytes if one EVM word was returned by the call.
        bool implementsHandler = false;
        if (data.length == 32) {
            bytes4 magic = abi.decode(data, (bytes4));
            implementsHandler = magic == IReceiver.handleMsg.selector;
        }

        if (status && implementsHandler) {
            messageStatus[messageRoot] = MessageStatus.EXECUTION_SUCCEEDED;
        } else {
            messageStatus[messageRoot] = MessageStatus.EXECUTION_FAILED;
        }

        emit PassMsg(
            message.sourceChainId,
            message.nonce,
            messageRoot,
            messageBytes,
            status
        );
    }

    /// @notice Decodes the message from messageBytes and checks conditions before message execution
    /// @param messageBytes The message we want to execute provided as bytes.
    function _checkPreconditions(
        bytes calldata messageBytes
    ) internal view returns (Message memory, bytes32) {
        Message memory message = MessageEncoding.decode(messageBytes);
        bytes32 messageRoot = keccak256(messageBytes);

        if (messageStatus[messageRoot] != MessageStatus.NOT_EXECUTED) {
            revert("Message already executed.");
        } else if (message.destinationChainId != block.chainid) {
            revert("Wrong chain.");
        } else if (message.version != version) {
            revert("Wrong version.");
        } else if (
            address(lightClients[message.sourceChainId]) == address(0) ||
            broadcasters[message.sourceChainId] == address(0)
        ) {
            revert("Light client or broadcaster for source chain is not set");
        }
        return (message, messageRoot);
    }

    /// @notice Checks that the chainId is not frozen.
    function requireNotFrozen(uint32 chainId) internal view {
        require(!frozen[chainId], "Contract is frozen.");
    }

    /// @notice Checks that the light client for a given chainId is consistent.
    // function requireLightClientConsistency(uint32 chainId) internal view {
    //     require(
    //         address(lightClients[chainId]) != address(0),
    //         "Light client is not set."
    //     );
    //     require(
    //         lightClients[chainId].consistent(),
    //         "Light client is inconsistent."
    //     );
    // }

    /// @notice Checks that the light client delay is adequate.
    // function requireLightClientDelay(
    //     uint64 slot,
    //     uint32 chainId
    // ) internal view {
    //     require(
    //         address(lightClients[chainId]) != address(0),
    //         "Light client is not set."
    //     );
    //     require(
    //         lightClients[chainId].timestamps(slot) != 0,
    //         "Timestamp is not set for slot."
    //     );
    //     uint256 elapsedTime = block.timestamp -
    //     lightClients[chainId].timestamps(slot);
    //     require(elapsedTime >= MIN_LIGHT_CLIENT_DELAY, "Must wait longer to use this slot.");
    // }
}
