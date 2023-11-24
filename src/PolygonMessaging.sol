// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IPolygonBridge} from "./interfaces/IPolygon.sol";
import {MessagingStorage} from "./MessagingStorage.sol";

contract PolygonMessaging is MessagingStorage {
    function polygonL1ToL2(
        bytes memory messageBytes,
        address target
    ) internal {
        IPolygonBridge bridge = IPolygonBridge(polygonL1Messager);
        uint32 destinationNetwork = 1;
        bool forceUpdateGlobalExitRoot = true;
        bridge.bridgeMessage(
            destinationNetwork,
            target,
            forceUpdateGlobalExitRoot,
            messageBytes
        );
    }

    function polygonL2ToL1(
        bytes memory messageBytes,
        address target
    ) internal {
        IPolygonBridge bridge = IPolygonBridge(polygonL2Messager);
        uint32 destinationNetwork = 0;
        bool forceUpdateGlobalExitRoot = true;
        bridge.bridgeMessage(
            destinationNetwork,
            target,
            forceUpdateGlobalExitRoot,
            messageBytes
        );
    }
}
