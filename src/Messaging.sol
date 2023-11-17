// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import {Relayer} from "./Relayer.sol";
import {Sender} from "./Sender.sol";
import {MessagingAccess} from "./MessagingAccess.sol";

/// @title Bridge Router
/// @author Succinct Labs
/// @notice Send and receive arbitrary messages from other chains.
contract Messaging is Sender, Relayer, MessagingAccess {
    /// @notice Returns current contract version.
    uint8 public constant VERSION = 1;

    constructor(bool _sendingEnabled) {
        zkSyncL2Value = 0;
        zkSyncL2GasLimit = 2000000;
        zkSyncL2GasPerPubdataByteLimit = 800;
        zkSyncToL2Value = 0.001 ether;

        sendingEnabled = _sendingEnabled;
        version = VERSION;
    }

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
