// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {MessagingStorage} from "./MessagingStorage.sol";
import {IZkSync} from "v2-testnet-contracts/l1/contracts/zksync/interfaces/IZkSync.sol";
import "v2-testnet-contracts/l2/system-contracts/Constants.sol";

contract ZkSyncMessaging is MessagingStorage {

    function zkSyncL1ToL2(bytes memory message, address routerAddr) internal {
        bytes memory _calldata = abi.encodeWithSignature("executeMessage(bytes)",message);

        IZkSync zksync = IZkSync(zkSyncAddress);
        zksync.requestL2Transaction{value: msg.value}(
            routerAddr,
            zkSyncL2Value,
            _calldata,
            zkSyncL2GasLimit,
            zkSyncL2GasPerPubdataByteLimit,
            zkSyncFactoryDeps,
            zkSyncRefundRecipient
        );
    }

    function zkSyncL2ToL1(bytes memory message) internal {
        L1_MESSENGER_CONTRACT.sendToL1(message);
    }
}