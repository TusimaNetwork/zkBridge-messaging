// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ILightClientGetter as ILightClient } from "zkBridge-messaging-interfaces/src/interfaces/ILightClient.sol";
import { MessageStatus } from "zkBridge-messaging-interfaces/src/interfaces/IMessaging.sol";

contract MessagingStorage {
    /*//////////////////////////////////////////////////////////////
                           BROADCASTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether sending is enabled or not.
    bool public sendingEnabled;

    bool public isDebugMode;

    /// @notice Mapping between a nonce and a message root.
    mapping(uint64 => bytes32) public messages;

    /// @notice Keeps track of the next nonce to be used.
    uint64 public nonce;

    /*//////////////////////////////////////////////////////////////
                           RECEIVER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice All sourceChainIds.
    uint32[] public sourceChainIds;

    /// @notice Mapping between source chainId and the corresponding light client.
    mapping(uint32 => ILightClient) public lightClients;

    /// @notice Mapping between source chainId and the address of the Bridge broadcaster on that chain.
    mapping(uint32 => address) public broadcasters;

    /// @notice Mapping between a source chainId and whether it's frozen.
    mapping(uint32 => bool) public frozen;

    /// @notice Mapping between a message root and its status.
    mapping(bytes32 => MessageStatus) public messageStatus;

    /*//////////////////////////////////////////////////////////////
                           SHARED STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns current contract version.
    uint8 public version;

    /*//////////////////////////////////////////////////////////////
                        RECEIVER STORAGE V2
    //////////////////////////////////////////////////////////////*/

    /// @notice Storage root cache.
    mapping(bytes32 => bytes32) public storageRootCache;

    /// @dev This empty reserved space is put in place to allow future versions to add new variables
    /// without shifting down storage in the inheritance chain.
    /// See: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[40] private __gap;

    mapping(address => bool) public msgRelayer;

    address public zkSyncAddress; 
    uint256 public zkSyncL2Value;
    uint256 public zkSyncL2GasLimit;
    uint256 public zkSyncL2GasPerPubdataByteLimit;
    bytes[] public zkSyncFactoryDeps;
    address public zkSyncRefundRecipient;
    uint256 public zkSyncToL2Value;

    address public scrollL1Messager;
    address public scrollL2Messager;
    uint256 public scrollL2GasLimit;
    address public rollupAddress;

    address public polygonL1Messager;
    address public polygonL2Messager;    
}
