// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ILightClientGetter as ILightClient } from "zkBridge-messaging-interfaces/src/interfaces/ILightClient.sol";

import {Relayer} from "./Relayer.sol";
import {Sender} from "./Sender.sol";
import {MessagingAccess} from "./MessagingAccess.sol";

/// @title Bridge Router
/// @author Succinct Labs
/// @notice Send and receive arbitrary messages from other chains.
contract Messaging is Sender, Relayer, MessagingAccess, UUPSUpgradeable {
    /// @notice Returns current contract version.
    uint8 public constant VERSION = 1;

    /// @notice Prevents the implementation contract from being initialized outside of the upgradeable proxy.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract and the parent contracts once.
    function initialize(
        uint32[] memory _sourceChainIds,
        address[] memory _lightClients,
        address[] memory _broadcasters,
        address _timelock,
        address _guardian,
        bool _sendingEnabled
    ) external initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _grantRole(GUARDIAN_ROLE, _guardian);
        _grantRole(TIMELOCK_ROLE, _timelock);
        _grantRole(DEFAULT_ADMIN_ROLE, _timelock);
        __UUPSUpgradeable_init();

        require(_sourceChainIds.length == _lightClients.length);
        require(_sourceChainIds.length == _broadcasters.length);

        sourceChainIds = _sourceChainIds;
        for (uint32 i = 0; i < sourceChainIds.length; i++) {
            lightClients[sourceChainIds[i]] = ILightClient(_lightClients[i]);
            broadcasters[sourceChainIds[i]] = _broadcasters[i];
        }
        sendingEnabled = _sendingEnabled;
        version = VERSION;
    }

    /// @notice Authorizes an upgrade for the implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyTimelock {}
}
