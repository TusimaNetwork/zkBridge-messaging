// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IReceiver} from "./IMessaging.sol";

abstract contract Receiver is IReceiver {
    error NotFromBridgeRouter(address sender);

    address public bridgeRouter;

    constructor(address _bridgeRouter) {
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
