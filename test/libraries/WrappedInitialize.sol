// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Messaging} from "src/Messaging.sol";

library WrappedInitialize {
    function init(
        address payable target,
        uint32 sourceChainId,
        address lightClient,
        address broadcaster,
        address timelock,
        address guardian
    ) internal {
        uint32[] memory sourceChainIds = new uint32[](1);
        sourceChainIds[0] = sourceChainId;
        address[] memory lightClients = new address[](1);
        lightClients[0] = lightClient;
        address[] memory broadcasters = new address[](1);
        broadcasters[0] = broadcaster;
        Messaging(target).initialize(
            sourceChainIds, lightClients, broadcasters, timelock, guardian, true
        );
    }
}
