// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IReceiver} from "./IMessaging.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ReceiverUpgradeable is IReceiver, Initializable {
    error NotFromBridgeRouter(address sender);

    address public bridgeRouter;

    function __BridgeHandler_init(address _bridgeRouter) public onlyInitializing {
        bridgeRouter = _bridgeRouter;
    }

    function handleMsg(uint32 sourceChainId, address sourceAddr, bytes memory message)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != bridgeRouter) {
            revert NotFromBridgeRouter(msg.sender);
        }
        handleBridgeImpl(sourceChainId, sourceAddr, message);
        return IReceiver.handleMsg.selector;
    }

    function handleBridgeImpl(uint32 sourceChainId, address sourceAddr, bytes memory message)
        internal
        virtual;
}
