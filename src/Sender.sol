// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Bytes32} from "./libraries/Typecast.sol";
import {MessageEncoding} from "./libraries/MessageEncoding.sol";
import {ISender, Message} from "./interfaces/IMessaging.sol";
import {MessagingStorage} from "./MessagingStorage.sol";
import {ZkSyncMessaging} from "./ZkSyncMessaging.sol";

import {IZkSync} from "v2-testnet-contracts/l1/contracts/zksync/interfaces/IZkSync.sol";
import "v2-testnet-contracts/l2/system-contracts/Constants.sol";

/// @title Source Arbitrary Message Bridge
/// @author Succinct Labs
/// @notice This contract is the entrypoint for sending messages to other chains.
contract Sender is ZkSyncMessaging, ISender {
    error SendingDisabled();
    error CannotSendToSameChain();

    event SendMsg(
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message
    );

    event SendZkSyncMsgL1ToL2(
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message
    );

    /// @notice Modifier to require that sending is enabled.
    modifier isSendingEnabled() {
        if (!sendingEnabled) {
            revert SendingDisabled();
        }
        _;
    }

    function send(
        uint32 targetChainId,
        address targetAddr,
        bytes calldata message
    ) external override isSendingEnabled returns (bytes32) {

        // TODO add limit for supporting chain

        if (targetChainId == block.chainid) revert CannotSendToSameChain();
        (bytes memory _message, bytes32 messageRoot) = _hashMsg(
            targetChainId,
            Bytes32.fromAddress(targetAddr),
            message
        );
        messages[nonce] = messageRoot;

        // zkSync l1 -> l2
        if (block.chainid == 5 && targetChainId == 280) {
            zkSyncL1ToL2(_message, chainRouter[targetChainId]);
            emit SendZkSyncMsgL1ToL2(nonce++, messageRoot, _message);
            return messageRoot;
        }

        // zkSync l2 -> l1
        if (block.chainid == 280 && targetChainId == 5) {
            bytes32 messageHash = zkSyncL2ToL1(_message);
        }

        emit SendMsg(nonce++, messageRoot, _message);
        return messageRoot;
    }

    /// @notice Gets the message and message root from the user-provided arguments to `send`
    /// @param targetChainId The chain id that specifies the destination chain.
    /// @param targetAddr The contract address that will be called on the destination chain.
    /// @param message The calldata used when calling the contract on the destination chain.
    /// @return messageBytes The message encoded as bytes, used in `SendMsg` event.
    /// @return messageRoot The hash of messageBytes, used as a unique identifier for a message.
    function _hashMsg(
        uint32 targetChainId,
        bytes32 targetAddr,
        bytes calldata message
    ) internal view returns (bytes memory messageBytes, bytes32 messageRoot) {
        messageBytes = MessageEncoding.encode(
            version,
            nonce,
            uint32(block.chainid),
            msg.sender,
            targetChainId,
            targetAddr,
            message
        );
        messageRoot = keccak256(messageBytes);
    }
}
