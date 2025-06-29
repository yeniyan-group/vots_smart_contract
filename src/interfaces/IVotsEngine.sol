// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IElection} from "./IElection.sol";

/**
 * @title IVotsEngine
 * @author Ayeni-yeniyan
 * @notice Interface for the VotsEngine contract
 * Defines the core voting system functionality
 */
interface IVotsEngine {
    // ====================================================================
    // Errors
    // ====================================================================
    error VotsEngine__DuplicateElectionName();
    error VotsEngine__ElectionNotFound();
    error VotsEngine__ElectionNameCannotBeEmpty();
    error VotsEngine__OnlyFunctionClient();
    error VotsEngine__FunctionClientNotSet();
    error VotsEngine__VaultAddressNotSet();

    // ====================================================================
    // Events
    // ====================================================================
    event ElectionContractedCreated(uint256 newElectionTokenId, string electionName);

    event FunctionClientUpdated(address indexed oldClient, address indexed newClient);
    event VaultAddressUpdated(address indexed oldVaultAddress, address indexed newVaultAddress);

    event VerificationRequestSent(bytes32 indexed requestId, string voterMatricNo, uint256 electionTokenId);

    // ====================================================================
    // Structs
    // ====================================================================
    struct ElectionSummary {
        uint256 electionId;
        string electionName;
        string electionDescription;
        IElection.ElectionState state;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 registeredVotersCount;
    }

    struct ElectionInfo {
        uint256 electionId;
        address createdBy;
        string electionName;
        string electionDescription;
        IElection.ElectionState state;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 registeredVotersCount;
        uint256 accreditedVotersCount;
        uint256 votedVotersCount;
        string[] electionCategories;
        address[] pollingOfficers;
        address[] pollingUnits;
        IElection.CandidateInfoDTO[] candidatesList;
    }

    // ====================================================================
    // Core Functions
    // ====================================================================

    /**
     * @dev Sets the function client address (only owner)
     * @param _functionClient Address of the VotsEngineFunctionClient contract
     */
    function setFunctionClient(address _functionClient) external;

    /**
     * @dev Creates a new election
     * @param params Election parameters
     */
    function createElection(IElection.ElectionParams calldata params) external;

    /**
     * @dev Accredits a voter for an election
     * @param voterMatricNo Voter's matriculation number
     * @param electionTokenId Token ID of the election
     */
    function accrediteVoter(string calldata voterMatricNo, uint256 electionTokenId) external;

    /**
     * @dev Called by VotsEngineFunctionClient to fulfill voter accreditation
     * @param voterMatricNo The voter's matriculation number
     * @param electionTokenId The election token ID
     * @param messageSender The original message sender who initiated the request
     */
    function fulfillVoterAccreditation(string calldata voterMatricNo, uint256 electionTokenId, address messageSender)
        external;

    /**
     * @dev Sends a verification request through the function client
     * @param ninNumber National identification number
     * @param firstName First name of the voter
     * @param lastName Last name of the voter
     * @param voterMatricNo Voter's matriculation number
     * @param slotId DON-hosted secrets slot ID
     * @param version DON-hosted secrets version
     * @param electionTokenId Token ID of the election
     * @param subscriptionId Chainlink Functions subscription ID
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
        uint64 subscriptionId
    ) external returns (bytes32 requestId);

    /**
     * @dev Allows a voter to vote for candidates
     * @param voterMatricNo Voter's matriculation number
     * @param voterName Voter's name
     * @param candidatesList List of candidates to vote for
     * @param electionTokenId Token ID of the election
     */
    function voteCandidates(
        string calldata voterMatricNo,
        string calldata voterName,
        IElection.CandidateInfoDTO[] calldata candidatesList,
        uint256 electionTokenId
    ) external;

    // ====================================================================
    // Validation Functions
    // ====================================================================

    /**
     * @dev Validates a voter for voting
     * @param voterMatricNo Voter's matriculation number
     * @param voterName Voter's name
     * @param electionTokenId Token ID of the election
     * @return bool True if voter is valid for voting
     */
    function validateVoterForVoting(string memory voterMatricNo, string memory voterName, uint256 electionTokenId)
        external
        returns (bool);

    /**
     * @dev Validates an address as a polling unit
     * @param electionTokenId Token ID of the election
     * @return bool True if address is a valid polling unit
     */
    function validateAddressAsPollingUnit(uint256 electionTokenId) external returns (bool);

    /**
     * @dev Validates an address as a polling officer
     * @param electionTokenId Token ID of the election
     * @return bool True if address is a valid polling officer
     */
    function validateAddressAsPollingOfficer(uint256 electionTokenId) external returns (bool);

    // ====================================================================
    // Getter Functions - Engine Level
    // ====================================================================

    /**
     * @dev Returns the total number of elections created
     * @return uint256 Total election count
     */
    function getTotalElectionsCount() external view returns (uint256);

    /**
     * @dev Returns the election contract address for a given token ID
     * @param electionTokenId The token ID of the election
     * @return address Election contract address
     */
    function getElectionAddress(uint256 electionTokenId) external view returns (address);

    /**
     * @dev Returns the token ID for a given election name
     * @param electionName The name of the election
     * @return uint256 Token ID (returns 0 if not found)
     */
    function getElectionTokenId(string calldata electionName) external view returns (uint256);

    /**
     * @dev Checks if an election exists by token ID
     * @param electionTokenId The token ID of the election
     * @return bool True if election exists
     */
    function electionExistsByTokenId(uint256 electionTokenId) external view returns (bool);

    /**
     * @dev Returns the current owner of the contract
     * @return address The owner address
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the current function client address
     * @return address The function client address
     */
    function getFunctionClient() external view returns (address);

    // ====================================================================
    // Getter Functions - Election Data Forwarding
    // ====================================================================

    /**
     * @dev Returns basic election information
     * @param electionTokenId The token ID of the election
     * @return ElectionInfo Election information
     */
    function getElectionInfo(uint256 electionTokenId) external view returns (ElectionInfo memory);

    /**
     * @dev Returns election statistics
     * @param electionTokenId The token ID of the election
     * @return registeredVotersCount Number of registered voters
     * @return accreditedVotersCount Number of accredited voters
     * @return votedVotersCount Number of voters who have voted
     * @return registeredCandidatesCount Number of registered candidates
     * @return pollingOfficerCount Number of polling officers
     * @return pollingUnitCount Number of polling units
     */
    function getElectionStats(uint256 electionTokenId)
        external
        view
        returns (
            uint256 registeredVotersCount,
            uint256 accreditedVotersCount,
            uint256 votedVotersCount,
            uint256 registeredCandidatesCount,
            uint256 pollingOfficerCount,
            uint256 pollingUnitCount
        );

    /**
     * @dev Returns all voters for an election
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionVoter[] Array of voters
     */
    function getAllVoters(uint256 electionTokenId) external view returns (IElection.ElectionVoter[] memory);

    /**
     * @dev Returns all accredited voters for an election
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionVoter[] Array of accredited voters
     */
    function getAllAccreditedVoters(uint256 electionTokenId) external view returns (IElection.ElectionVoter[] memory);

    /**
     * @dev Returns all voters who have voted for an election
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionVoter[] Array of voters who have voted
     */
    function getAllVotedVoters(uint256 electionTokenId) external view returns (IElection.ElectionVoter[] memory);

    /**
     * @dev Returns all candidates for an election (as DTOs)
     * @param electionTokenId The token ID of the election
     * @return IElection.CandidateInfoDTO[] Array of candidate DTOs
     */
    function getAllCandidatesInDto(uint256 electionTokenId)
        external
        view
        returns (IElection.CandidateInfoDTO[] memory);

    /**
     * @dev Returns all candidates with vote counts (only after election ends)
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionCandidate[] Array of candidates with vote counts
     */
    function getAllCandidates(uint256 electionTokenId) external returns (IElection.ElectionCandidate[] memory);

    /**
     * @dev Returns winners for each category (handles ties)
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionWinner[][] Array of winners for each category
     */
    function getEachCategoryWinner(uint256 electionTokenId) external returns (IElection.ElectionWinner[][] memory);

    // ====================================================================
    // Utility Functions
    // ====================================================================

    /**
     * @dev Updates election state for a specific election
     * @param electionTokenId The token ID of the election
     */
    function updateElectionState(uint256 electionTokenId) external;

    /**
     * @dev Returns a summary of all elections (basic info only)
     * @return electionsSummaryList Array of election summaries
     */
    function getAllElectionsSummary() external view returns (ElectionSummary[] memory electionsSummaryList);
}
