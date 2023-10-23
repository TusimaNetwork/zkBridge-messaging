// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { ILightClientGetter as ILightClient } from "zkBridge-messaging-interfaces/src/interfaces/ILightClient.sol";
import {MessagingStorage} from "./MessagingStorage.sol";

contract MessagingAccess is MessagingStorage, AccessControlUpgradeable {
    /// @notice Emitted when the sendingEnabled flag is changed.
    event SendingEnabled(bool enabled);

    /// @notice Emitted when freezeAll is called.
    event FreezeAll();

    /// @notice Emitted when freeze is called.
    event Freeze(uint32 indexed chainId);

    /// @notice Emitted when unfreezeAll is called.
    event UnfreezeAll();

    /// @notice Emitted when unfreeze is called.
    event Unfreeze(uint32 indexed chainId);

    /// @notice Emitted when setLightClientAndBroadcaster is called.
    event SetLightClientAndBroadcaster(
        uint32 indexed chainId,
        address lightClient,
        address broadcaster
    );

    /// @notice Emitted when a new source chain is added.
    event SourceChainAdded(uint32 indexed chainId);

    /// @notice A random constant used to identify addresses with the permission of a 'guardian'.
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice A random constant used to identify addresses with the permission of a 'timelock'.
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "MessagingAccess: only admin can call this function"
        );
        _;
    }

    modifier onlyTimelock() {
        require(
            hasRole(TIMELOCK_ROLE, msg.sender),
            "MessagingAccess: only timelock can call this function"
        );
        _;
    }

    modifier onlyGuardian() {
        require(
            hasRole(GUARDIAN_ROLE, msg.sender),
            "MessagingAccess: only guardian can call this function"
        );
        _;
    }

    /// @notice Allows the owner to control whether sending is enabled or not.
    function setSendingEnabled(bool enabled) external onlyGuardian {
        sendingEnabled = enabled;
        emit SendingEnabled(enabled);
    }

    /// @notice Freezes messages from all chains.
    /// @dev This is a safety mechanism to prevent the contract from being used after a security
    ///      vulnerability is detected.
    function freezeAll() external onlyGuardian {
        for (uint32 i = 0; i < sourceChainIds.length; i++) {
            frozen[sourceChainIds[i]] = true;
        }
        emit FreezeAll();
    }

    /// @notice Freezes messages from the specified chain.
    /// @dev This is a safety mechanism to prevent the contract from being used after a security
    ///      vulnerability is detected.
    function freeze(uint32 chainId) external onlyGuardian {
        frozen[chainId] = true;
        emit Freeze(chainId);
    }

    /// @notice Unfreezes messages from the specified chain.
    /// @dev This is a safety mechanism to continue usage of the contract after a security
    ///      vulnerability is patched.
    function unfreeze(uint32 chainId) external onlyGuardian {
        frozen[chainId] = false;
        emit Unfreeze(chainId);
    }

    /// @notice Unfreezes messages from all chains.
    /// @dev This is a safety mechanism to continue usage of the contract after a security
    ///      vulnerability is patched.
    function unfreezeAll() external onlyGuardian {
        for (uint32 i = 0; i < sourceChainIds.length; i++) {
            frozen[sourceChainIds[i]] = false;
        }
        emit UnfreezeAll();
    }

    /// @notice Sets the light client contract and broadcaster for a given chainId.
    /// @dev This is controlled by the timelock as it is a potentially dangerous method
    ///      since both the light client and broadcaster address are critical in verifying
    ///      that only valid sent messages are executed.
    function setLightClientAndBroadcaster(
        uint32 chainId,
        address lightclient,
        address broadcaster
    ) external onlyTimelock {
        bool chainIdExists = false;
        for (uint256 i = 0; i < sourceChainIds.length; i++) {
            if (sourceChainIds[i] == chainId) {
                chainIdExists = true;
                break;
            }
        }
        if (!chainIdExists) {
            sourceChainIds.push(chainId);
            emit SourceChainAdded(chainId);
        }
        lightClients[chainId] = ILightClient(lightclient);
        broadcasters[chainId] = broadcaster;
        emit SetLightClientAndBroadcaster(chainId, lightclient, broadcaster);
    }

    function setRelayer(address _relayer, bool _isTrue) external onlyAdmin {
        msgRelayer[_relayer] = _isTrue;
    }

    function setChainRouter(uint32 _chainId, address _routerAddress) external onlyAdmin {
        chainRouter[_chainId] = _routerAddress;
    }

    function setZKSyncAddress(address _zkSyncAddress) external onlyAdmin {
        zkSyncAddress = _zkSyncAddress;
    }

    function setZkSyncL2Value(uint256 _l2Value) external onlyAdmin {
        zkSyncL2Value = _l2Value;
    }

    function setZkSyncGasLimit(uint256 _gasLimit) external onlyAdmin{
        zkSyncL2GasLimit = _gasLimit;
    }

    function setZkSyncL2GasPerPubdataByteLimit(uint256 byteLimit) external onlyAdmin {
        zkSyncL2GasPerPubdataByteLimit = byteLimit;
    }

    function setZkSyncFactoryDeps(bytes[] memory value) external onlyAdmin {
        zkSyncFactoryDeps = value;
    }

    function setZkSyncRefundRecipient(address recipient) external onlyAdmin {
        zkSyncRefundRecipient = recipient;
    }

    function setZkSyncToL2Value(uint256 value) external onlyAdmin {
        zkSyncToL2Value = value;
    }

    /*
     * @description: change debug mode
     * @return {*}
     * @param {bool} isDebug
     */
    function changeDebugMode(bool isDebug) external onlyAdmin {
        isDebugMode = isDebug;
    }
}
