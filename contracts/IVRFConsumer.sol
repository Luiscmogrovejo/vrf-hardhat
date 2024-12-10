// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFConsumer {
    /**
     * @notice Oracle calls this when randomness is ready.
     * @param requestId The ID of the randomness request.
     * @param outputs Randomness output.
     */
    function fulfillRandomness(
        uint256 requestId,
        bytes32[] memory outputs
    ) external;
}
