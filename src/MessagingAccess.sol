// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ILightClientGetter as ILightClient} from "zkBridge-messaging-interfaces/src/interfaces/ILightClient.sol";
import {MessagingStorage} from "./MessagingStorage.sol";

contract MessagingAccess is MessagingStorage, Ownable {
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
    // event SetLightClientAndBroadcaster(
    //     uint32 indexed chainId,
    //     address lightClient,
    //     address broadcaster
    // );

    /// @notice Emitted when a new source chain is added.
    event SourceChainAdded(uint32 indexed chainId);

    /// @notice Allows the owner to control whether sending is enabled or not.
    function setSendingEnabled(bool enabled) external onlyOwner {
        sendingEnabled = enabled;
        emit SendingEnabled(enabled);
    }

    /// @notice Freezes messages from all chains.
    /// @dev This is a safety mechanism to prevent the contract from being used after a security
    ///      vulnerability is detected.
    function freezeAll() external onlyOwner {
        for (uint32 i = 0; i < sourceChainIds.length; i++) {
            frozen[sourceChainIds[i]] = true;
        }
        emit FreezeAll();
    }

    /// @notice Freezes messages from the specified chain.
    /// @dev This is a safety mechanism to prevent the contract from being used after a security
    ///      vulnerability is detected.
    function freeze(uint32 chainId) external onlyOwner {
        frozen[chainId] = true;
        emit Freeze(chainId);
    }

    /// @notice Unfreezes messages from the specified chain.
    /// @dev This is a safety mechanism to continue usage of the contract after a security
    ///      vulnerability is patched.
    function unfreeze(uint32 chainId) external onlyOwner {
        frozen[chainId] = false;
        emit Unfreeze(chainId);
    }

    /// @notice Unfreezes messages from all chains.
    /// @dev This is a safety mechanism to continue usage of the contract after a security
    ///      vulnerability is patched.
    function unfreezeAll() external onlyOwner {
        for (uint32 i = 0; i < sourceChainIds.length; i++) {
            frozen[sourceChainIds[i]] = false;
        }
        emit UnfreezeAll();
    }

    /// @notice Sets the light client contract and broadcaster for a given chainId.
    /// @dev This is controlled by the timelock as it is a potentially dangerous method
    ///      since both the light client and broadcaster address are critical in verifying
    ///      that only valid sent messages are executed.
    // function setLightClientAndBroadcaster(
    //     uint32 chainId,
    //     address lightclient,
    //     address broadcaster
    // ) external onlyOwner {
    //     bool chainIdExists = false;
    //     for (uint256 i = 0; i < sourceChainIds.length; i++) {
    //         if (sourceChainIds[i] == chainId) {
    //             chainIdExists = true;
    //             break;
    //         }
    //     }
    //     if (!chainIdExists) {
    //         sourceChainIds.push(chainId);
    //         emit SourceChainAdded(chainId);
    //     }
    //     lightClients[chainId] = ILightClient(lightclient);
    //     broadcasters[chainId] = broadcaster;
    //     emit SetLightClientAndBroadcaster(chainId, lightclient, broadcaster);
    // }

    function setLightClient(
        uint32[] memory chainIds,
        address[] memory lightclient
    ) external onlyOwner {
        for (uint256 i = 0; i < chainIds.length; i++) {
            lightClients[chainIds[i]] = ILightClient(lightclient[i]);
        }
    }

    function setBroadcaster(
        uint32[] memory chainIds,
        address[] memory broadcaster
    ) external onlyOwner {
        for (uint256 i = 0; i < chainIds.length; i++) {
            broadcasters[chainIds[i]] = broadcaster[i];
        }
    }

    function setRelayer(address _relayer, bool _isTrue) external onlyOwner {
        msgRelayer[_relayer] = _isTrue;
    }

    function setZKSync(
        address _zkSyncAddress,
        uint256 _l2Value,
        uint256 _gasLimit,
        uint256 _byteLimit,
        bytes[] memory _factoryDeps,
        address _recipient,
        uint256 _value
    ) external onlyOwner {
        zkSyncAddress = _zkSyncAddress;
        zkSyncL2Value = _l2Value;
        zkSyncL2GasLimit = _gasLimit;
        zkSyncL2GasPerPubdataByteLimit = _byteLimit;
        zkSyncFactoryDeps = _factoryDeps;
        zkSyncRefundRecipient = _recipient;
        zkSyncToL2Value = _value;
    }

    function setScroll(
        address _scrollL1Messager,
        address _scrollL2Messager,
        uint256 _scrollL2GasLimit,
        address _rollupAddress
    ) external onlyOwner {
        scrollL1Messager = _scrollL1Messager;
        scrollL2Messager = _scrollL2Messager;
        scrollL2GasLimit = _scrollL2GasLimit;
        rollupAddress = _rollupAddress;
    }

    function setPolygon(
        address _polygonL1Messager,
        address _polugonL2Messager
    ) external onlyOwner {
        polygonL1Messager = _polygonL1Messager;
        polygonL2Messager = _polugonL2Messager;
    }

    /*
     * @description: change debug mode
     * @return {*}
     * @param {bool} isDebug
     */
    function changeDebugMode(bool isDebug) external onlyOwner {
        isDebugMode = isDebug;
    }

    function withdraw(address receiver, uint256 amount) external onlyOwner {
        (bool success, ) = payable(receiver).call{value: amount}("");
        require(success, "Withdraw Fail!");
    }
}
