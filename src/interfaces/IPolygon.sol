//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title The bridge interface implemented on both chains
interface IPolygonBridge {
    function bridgeMessage(
        uint32 destinationNetwork,
        address destinationAddress,
        bool forceUpdateGlobalExitRoot,
        bytes calldata metadata
    ) external payable;

    function claimMessage(
        bytes32[32] calldata smtProof,
        uint32 index,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originTokenAddress,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external;

    function verifyMerkleProof(
        bytes32 leafHash,
        bytes32[32] memory smtProof,
        uint32 index,
        bytes32 root
    ) external returns (bool);
}

interface IPolygonInterface {
    // scroll -- L1 -> L2
    // scroll -- L2 -> L1
    function vMsgPolygon(
        bytes32[32] calldata smtProof,
        uint32 index,
        bytes32 exitRoot,
        bytes calldata messageBytes
    ) external;
}
