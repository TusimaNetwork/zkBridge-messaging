// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED,
    EXECUTION_SUCCEEDED
}

struct Message {
    uint8 version;
    uint64 nonce;
    uint32 sourceChainId;
    address sourceAddress;
    uint32 destinationChainId;
    bytes32 destinationAddress;
    bytes data;
}

interface ISender {
    function send(
        uint32 targetChainId,
        address targetAddr,
        bytes calldata message
    ) external returns (bytes32);
}

interface IRelayer {
    // ethereum --> anywhere, debug version
    function vMsg(
        uint64 slot,
        bytes calldata message,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external;

    // layer 1 --> zkSync
    function vMsgZkSyncL1ToL2(
        bytes calldata messageBytes
    ) external;

    // zkSync --- l2 --> l1
    function vMsgZkSyncL2ToL1(
        // address _zkSyncAddress,
        address _someSender,
        // zkSync block number in which the message was sent
        uint256 _l1BatchNumber,
        // Message index, that can be received via API
        uint256 _proofId,
        // The tx number in block
        uint16 _trxIndex,
        // The message that was sent from l2
        bytes calldata _messageBytes,
        // Merkle proof for the message
        bytes32[] calldata _proof
    ) external;
}

interface IReceiver {
    function handleMsg(
        uint32 sourceChainId,
        address sourceAddr,
        bytes memory message
    ) external returns (bytes4);
}
