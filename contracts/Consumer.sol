// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVRFConsumer.sol";

interface IVRFOracle {
    function requestRandomness(uint256 words) external payable returns (uint256);
}

/**
 * @title Example Consumer Contract
 */
contract MyRandomConsumer is IVRFConsumer {
    address public oracle;
    mapping(uint256 => bytes32[]) public requestIdToRandomness;

    event RandomnessRequested(uint256 indexed requestId, uint256 words);
    event RandomnessFulfilled(uint256 indexed requestId, bytes32[] outputs);

    constructor(address oracleAddress) {
        oracle = oracleAddress;
    }

    function requestMyRandomness(
        uint256 words,
        uint256 deadline,
        uint8 priority
    ) external payable {
        // Assume the oracle has a function signature:
        // requestRandomness(uint256 words, uint256 deadline, uint8 priority) external payable returns (uint256)
        (bool success, bytes memory data) = oracle.call{value: msg.value}(
            abi.encodeWithSignature("requestRandomness(uint256,uint256,uint8)", words, deadline, priority)
        );
        require(success, "Request failed");
        uint256 requestId = abi.decode(data, (uint256));
        emit RandomnessRequested(requestId, words);
    }

    function fulfillRandomness(
        uint256 requestId,
        bytes32[] memory outputs
    ) external override {
        require(msg.sender == oracle, "Only the oracle can fulfill");
        requestIdToRandomness[requestId] = outputs;
        emit RandomnessFulfilled(requestId, outputs);
    }
}
