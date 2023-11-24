// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {MessagingStorage} from "./MessagingStorage.sol";
import {IL1MessageQueue} from "./interfaces/IScrollChain.sol";
import {IScrollMessenger,IL1ScrollMessenger} from "./interfaces/IScrollMessenger.sol";

contract ScrollMessaging is MessagingStorage {
    // scroll -- L1 -> L2
    function scrollL1ToL2(
        bytes memory messageBytes,
        address target
    ) internal {
        bytes memory _calldata = abi.encodeWithSignature(
            "vMsgScrollL1ToL2(bytes)",
            messageBytes
        );

        IL1ScrollMessenger scrollMessenger = IL1ScrollMessenger(
            scrollL1Messager
        );

        IL1MessageQueue l1MessageQueue = IL1MessageQueue(
            scrollMessenger.messageQueue()
        );

        uint256 fee = l1MessageQueue.estimateCrossDomainMessageFee(scrollL2GasLimit);

        scrollMessenger.sendMessage{value: fee}(
            target,
            0,
            _calldata,
            scrollL2GasLimit,
            target
        );
    }

    // scroll -- L2 -> L1
    function scrollL2ToL1(
        bytes memory messageBytes,
        address target
    ) internal {
        IScrollMessenger scrollMessenger = IScrollMessenger(
            scrollL2Messager
        );

        scrollMessenger.sendMessage(
            target,
            0,
            messageBytes,
            0
        );
    }
}
