//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IL1MessageQueue {
    /// @notice Return the amount of ETH should pay for cross domain message.
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    function estimateCrossDomainMessageFee(
        uint256 gasLimit
    ) external view returns (uint256);
}

interface IScrollChain {
    /// @notice Return whether the batch is finalized by batch index.
    /// @param batchIndex The index of the batch.
    function isBatchFinalized(uint256 batchIndex) external view returns (bool);

    /// @notice Return the message root of a committed batch.
    /// @param batchIndex The index of the batch.
    function withdrawRoots(uint256 batchIndex) external view returns (bytes32);
}