// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVRFConsumer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library VRFVerifier {
    using ECDSA for bytes32;

    function verifyECVRFProof(
        bytes memory publicKey,
        bytes32 seed,
        bytes32 output,
        bytes memory proof
    ) internal pure returns (bool valid) {
        // 1. Basic validation: the proof must be exactly 96 bytes (this is a given format requirement).
        require(proof.length == 96, "Invalid proof length");

        // 2. Extract components of the proof: gamma, c, and s.
        //    Typically, a VRF proof consists of several parts, often related to elliptic curve points and scalars.
        bytes memory gamma = slice(proof, 0, 32);
        bytes32 c = bytesToBytes32(slice(proof, 32, 32));
        bytes32 s = bytesToBytes32(slice(proof, 64, 32));

        // 3. Compute a hash (h) from the public key and seed. This represents the challenge/input to the VRF.
        bytes32 h = sha256(abi.encodePacked(publicKey, seed));

        // 4. Compute cPrime, another hash based on the public key, gamma, h, and s.
        //    In a real ECVRF scheme, c is a challenge scalar derived from hashing certain curve points.
        bytes32 cPrime = sha256(abi.encodePacked(publicKey, gamma, h, s));

        // 5. Check if cPrime matches c and if the provided output matches sha256(gamma).
        //    This is a simplified verification step. Real VRF verification involves more intricate elliptic curve operations.
        if (cPrime != c || output != sha256(gamma)) {
            return false;
        }

        return true;
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(data.length >= start + length, "Invalid slice length");
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)
            let lengthMod := and(length, 31)
            let mc := add(tempBytes, lengthMod)
            let end := add(mc, length)

            for {
                let cc := add(add(data, lengthMod), start)
            } lt(mc, end) {
                mc := add(mc, 32)
                cc := add(cc, 32)
            } {
                mstore(mc, mload(cc))
            }

            mstore(tempBytes, length)
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        return tempBytes;
    }

    function bytesToBytes32(
        bytes memory b
    ) internal pure returns (bytes32 result) {
        require(b.length == 32, "Invalid bytes length");
        assembly {
            result := mload(add(b, 32))
        }
    }
}

contract VRFOracleWithCallback {
    bytes public vrfPublicKey;

    struct RandomnessRequest {
        address requester;
        uint256 words;
        bool fulfilled;
        uint256 feePaid;
        uint256 deadline;
        uint8 priority;
    }

    uint256 private requestCounter;
    mapping(uint256 => RandomnessRequest) public requests;

    event RandomnessRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint256 words,
        uint256 fee,
        uint256 deadline,
        uint8 priority
    );
    event RandomnessFulfilled(uint256 indexed requestId, bytes32[] outputs);

    constructor(bytes memory _vrfPublicKey) {
        vrfPublicKey = _vrfPublicKey;
    }

    function requestRandomness(
        uint256 words,
        uint256 fee,
        uint256 deadline,
        uint8 priority
    ) external payable returns (uint256 requestId) {
        require(msg.value >= fee, "Insufficient fee");
        require(words > 0, "Words must be greater than zero");

        requestId = ++requestCounter;
        requests[requestId] = RandomnessRequest({
            requester: msg.sender,
            words: words,
            fulfilled: false,
            feePaid: fee,
            deadline: deadline,
            priority: priority
        });

        emit RandomnessRequested(
            requestId,
            msg.sender,
            words,
            fee,
            deadline,
            priority
        );
    }

    function fulfillRandomness(
        uint256 requestId,
        bytes32[] memory outputs,
        bytes memory proof
    ) external {
        RandomnessRequest storage req = requests[requestId];
        require(!req.fulfilled, "Already fulfilled");
        require(req.requester != address(0), "Invalid requestId");
        require(outputs.length == req.words, "Incorrect number of outputs");

        // Verify each output with proof
        for (uint256 i = 0; i < outputs.length; i++) {
            require(
                verifyVRFProof(vrfPublicKey, bytes32(i), outputs[i], proof),
                "Invalid VRF proof"
            );
        }

        req.fulfilled = true;

        emit RandomnessFulfilled(requestId, outputs);

        IVRFConsumer consumer = IVRFConsumer(req.requester);
        consumer.fulfillRandomness(requestId, outputs);
    }

    function verifyVRFProof(
        bytes memory publicKey,
        bytes32 seed,
        bytes32 output,
        bytes memory proof
    ) internal pure returns (bool) {
        return VRFVerifier.verifyECVRFProof(publicKey, seed, output, proof);
    }
}
