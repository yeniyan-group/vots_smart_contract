// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IVotsEngineFunctionClient
 * @author Ayeni-yeniyan
 * @notice Interface for the VotsEngineFunctionClient contract
 * Defines the contract that handles Chainlink Functions requests for voter verification
 */
interface IVotsEngineFunctionClient {
    // ====================================================================
    // Errors
    // ====================================================================
    error VotsEngineFunctionClient__OnlyVotsEngine();
    error VotsEngineFunctionClient__InvalidRequestId();

    // ====================================================================
    // Events
    // ====================================================================
    event VerificationRequestSent(
        bytes32 indexed requestId,
        string voterMatricNo,
        uint256 electionTokenId
    );

    event VerificationRequestFulfilled(
        bytes32 indexed requestId,
        string voterMatricNo,
        uint256 electionTokenId
    );

    // ====================================================================
    // Structs
    // ====================================================================
    struct RequestInfo {
        uint256 electionTokenId;
        address messageSender;
        string voterMatricNo;
        bool exists;
    }

    // ====================================================================
    // Functions
    // ====================================================================

    /**
     * @dev Sends an HTTP request to an ID verification portal
     * @param ninNumber National identification number
     * @param firstName First name of the voter
     * @param lastName Last name of the voter
     * @param voterMatricNo Voter's matriculation number
     * @param slotId DON-hosted secrets slot ID
     * @param version DON-hosted secrets version
     * @param electionTokenId Token ID of the election
     * @param subscriptionId Chainlink Functions subscription ID
     * @param messageSender Original message sender who initiated the request
     * @return requestId The ID of the request
     */
    function sendVerificationRequestForElection(
        string calldata ninNumber,
        string calldata firstName,
        string calldata lastName,
        string calldata voterMatricNo,
        uint256 slotId,
        uint256 version,
        uint256 electionTokenId,
        uint64 subscriptionId,
        address messageSender
    ) external returns (bytes32 requestId);

    /**
     * @dev Returns the DON ID used by this contract
     * @return bytes32 The DON ID
     */
    function getDonId() external view returns (bytes32);

    /**
     * @dev Returns the VotsEngine contract address
     * @return address The VotsEngine contract address
     */
    function votsEngine() external view returns (address);

    /**
     * @dev Returns request information for a given request ID
     * @param requestId The request ID to query
     * @return RequestInfo The request information
     */
    function getRequestInfo(
        bytes32 requestId
    ) external view returns (RequestInfo memory);

    /**
     * @dev Checks if a request exists
     * @param requestId The request ID to check
     * @return bool True if the request exists
     */
    function requestExists(bytes32 requestId) external view returns (bool);
}
