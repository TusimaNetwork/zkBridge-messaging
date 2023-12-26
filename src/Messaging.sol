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
        zkSyncAddress = 0x9A6DE0f62Aa270A8bCB1e2610078650D539B1Ef9;
        zkSyncL2Value = 0;
        zkSyncL2GasLimit = 2000000;
        zkSyncL2GasPerPubdataByteLimit = 800;
        zkSyncToL2Value = 0.001 ether;

        scrollL1Messager = 0x50c7d3e7f7c656493D1D76aaa1a836CedfCBB16A;
        scrollL2Messager = 0xBa50f5340FB9F3Bd074bD638c9BE13eCB36E603d;
        scrollL2GasLimit = 2000000;
        rollupAddress = 0x2D567EcE699Eabe5afCd141eDB7A4f2D0D6ce8a0;

        polygonL1Messager = 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7;
        polygonL2Messager = 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7;

        sendingEnabled = _sendingEnabled;
        version = VERSION;
    }

    event Received(address sender, uint amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
