// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFConsumer {
    function fulfillRandomness(
        uint256 requestId,
        bytes32[] memory outputs,
        bytes memory proof,
        uint256 randomNumber
    ) external;
}

interface IVRFOracle {
    function requestRandomness(
        uint256 num_values,
        uint256 fee,
        uint256 deadline,
        uint8 priority
    ) external payable returns (uint256);
}

/**
 * @title ImprovedRandomConsumer
 * @dev A more robust contract that can handle multiple randomness requests and store results.
 */
contract ImprovedRandomConsumer is IVRFConsumer {
    address public immutable oracle;

    struct Request {
        address requester;
        uint256 words;
        bool fulfilled;
        bytes32[] randomness;
        uint256 randomNumber;
    }

    // Mapping from request ID to Request details
    mapping(uint256 => Request) public requests;

    event RandomnessRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint256 words
    );
    event RandomnessFulfilled(uint256 indexed requestId, bytes32[] randomness);

    /**
     * @dev Sets the oracle address that will be used to request randomness.
     * @param oracleAddress The address of the VRF oracle contract.
     */
    constructor(address oracleAddress) {
        require(oracleAddress != address(0), "Invalid oracle address");
        oracle = oracleAddress;
    }

    /**
     * @notice Request a specified number of random words from the oracle.
     * @dev This function sends a fee (via msg.value) to pay for the request if required.
     * @param words The number of random words requested.
     * @return requestId The ID of the newly created randomness request.
     */
    function requestMyRandomness(
        uint256 words
    ) external payable returns (uint256 requestId) {
        require(words > 0, "Number of words must be greater than zero");

        // Request random words from the oracle
        requestId = IVRFOracle(oracle).requestRandomness{value: msg.value}(
            words,
            msg.value,
            0,
            1
        );

        // Store the request data
        requests[requestId] = Request({
            requester: msg.sender,
            words: words,
            fulfilled: false,
            randomness: new bytes32[](0),
            randomNumber: 0
        });

        emit RandomnessRequested(requestId, msg.sender, words);
    }

    /**
     * @notice Called by the oracle to deliver the randomness to this contract.
     * @dev Only the oracle can fulfill requests.
     * @param requestId The ID of the randomness request being fulfilled.
     * @param outputs An array containing the random words.
     * @param proof The proof of randomness (not used in this contract).
     * @param randomNumber The random number (not used in this contract).
     */
    function fulfillRandomness(
        uint256 requestId,
        bytes32[] memory outputs,
        bytes memory proof,
        uint256 randomNumber
    ) external override {
        require(msg.sender == oracle, "Only the oracle can fulfill randomness");
        require(
            requests[requestId].requester != address(0),
            "Invalid request ID"
        );
        require(!requests[requestId].fulfilled, "Already fulfilled");

        // Update the request record to indicate fulfillment
        requests[requestId].fulfilled = true;
        requests[requestId].randomness = outputs;
        requests[requestId].randomNumber = randomNumber;
        emit RandomnessFulfilled(requestId, outputs);
    }

    /**
     * @notice Check whether a particular request has been fulfilled.
     * @param requestId The ID of the request to check.
     * @return True if the request has been fulfilled, false otherwise.
     */
    function isFulfilled(uint256 requestId) external view returns (bool) {
        return requests[requestId].fulfilled;
    }

    /**
     * @notice Retrieve the randomness associated with a fulfilled request.
     * @dev Reverts if the request is not fulfilled yet.
     * @param requestId The ID of the request to retrieve randomness for.
     * @return An array of random words.
     */
    function getRandomness(
        uint256 requestId
    ) external view returns (bytes32[] memory) {
        require(requests[requestId].fulfilled, "Randomness not received yet");
        return requests[requestId].randomness;
    }
}
