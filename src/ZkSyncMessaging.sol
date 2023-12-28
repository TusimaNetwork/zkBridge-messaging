// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {MessagingStorage} from "./MessagingStorage.sol";
import {IZkSync, L1_MESSENGER_CONTRACT} from "./interfaces/IZkSync.sol";

contract ZkSyncMessaging is MessagingStorage {
    function zkSyncL1ToL2(bytes memory message, address routerAddr) internal {
        bytes memory _calldata = abi.encodeWithSignature(
            "vMsgZkSyncL1ToL2(bytes)",
            message
        );

        IZkSync zksync = IZkSync(zkSyncAddress);

        uint256 l2TxFee = zksync.l2TransactionBaseCost(tx.gasprice, zkSyncL2GasLimit, zkSyncL2GasPerPubdataByteLimit);
        // TODO Cause we don't charge any fee for now, but zkSync does, so we pay for them at this version.
        zksync.requestL2Transaction{value: l2TxFee}(
            routerAddr,
            zkSyncL2Value,
            _calldata,
            zkSyncL2GasLimit,
            zkSyncL2GasPerPubdataByteLimit,
            zkSyncFactoryDeps,
            routerAddr
        );
    }

    function zkSyncL2ToL1(bytes memory message) internal returns (bytes32) {
        return L1_MESSENGER_CONTRACT.sendToL1(message);
    }
}
