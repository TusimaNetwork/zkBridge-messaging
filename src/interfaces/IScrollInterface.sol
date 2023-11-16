// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IScroll {
     // scroll -- L1 -> L2
    function vMsgScrollL1ToL2(bytes calldata messageBytes) external;

    // scroll -- L2 -> L1
    function vMsgScrollL2ToL1(uint256 nonce,uint256 batchIndex,bytes calldata proof,bytes calldata messageBytes) external;
}