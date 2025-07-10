// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IElection
 * @dev Interface for the Election contract containing only functions called by VotsEngine
 * @author Ayeni-yeniyan
 * @notice Interface for individual election contracts managed by VotsEngine
 */
interface IElection {
    // ====================================================================
    // Structs (Referenced by VotsEngine)
    // ====================================================================

    enum ElectionState {
        OPENED,
        STARTED,
        ENDED
    }

    enum CandidateState {
        UNKNOWN,
        REGISTERED
    }

    /**
     * @dev Voters state Enum
     */
    enum VoterState {
        UNKNOWN,
        REGISTERED,
        ACCREDITED,
        VOTED
    }

    struct ElectionParams {
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        string electionName;
        string description;
        CandidateInfoDTO[] candidatesList;
        VoterInfoDTO[] votersList;
        PollIdentifier[] pollingUnits;
        PollIdentifier[] pollingOfficers;
        string[] electionCategories;
    }

    /**
     * @dev This is for storing the unregistered candidates only
     */
    struct CandidateInfoDTO {
        string name;
        string matricNo;
        string category;
        uint256 voteFor;
        uint256 voteAgainst;
    }

    /**
     * @dev This structure is for registering voters only
     */
    struct VoterInfoDTO {
        string name;
        string matricNo;
        string department;
        uint256 level;
    }

    /**
     * @dev Defines the structure of our voter
     */
    struct ElectionVoter {
        string name;
        string department;
        uint256 level;
        VoterState voterState;
    }

    /**
     * @dev Structure for election candidates
     */
    struct ElectionCandidate {
        string name;
        uint256 votes;
        uint256 votesAgainst;
        CandidateState state;
    }

    /**
     * @dev Winner of each election category
     */
    struct ElectionWinner {
        string matricNo;
        ElectionCandidate electionCandidate;
        string category;
    }

    /**
     * @dev Structure for Polling Unit Identifier
     */
    struct PollIdentifier {
        string pollRoleName;
        address pollAddress;
    }

    // ====================================================================
    // Voter Management Functions
    // ====================================================================

    /**
     * @dev Accredits a voter for this election
     * @param voterMatricNo The voter's matriculation number
     * @param accreditedBy Address that accredited the voter
     */
    function accrediteVoter(
        string calldata voterMatricNo,
        address accreditedBy
    ) external;

    /**
     * @dev Validates if a voter can vote in this election
     * @param voterName The voter's name
     * @param voterMatricNo The voter's matriculation number
     * @param votedBy Address attempting to vote
     * @return bool True if voter is valid for voting
     */
    function validateVoterForVoting(
        string memory voterName,
        string memory voterMatricNo,
        address votedBy
    ) external returns (bool);

    /**
     * @dev Processes votes for candidates
     * @param voterMatricNo The voter's matriculation number
     * @param voterName The voter's name
     * @param votedBy Address that cast the vote
     * @param candidatesList List of candidates being voted for
     */
    function voteCandidates(
        string calldata voterMatricNo,
        string calldata voterName,
        address votedBy,
        CandidateInfoDTO[] calldata candidatesList
    ) external;

    // ====================================================================
    // Validation Functions
    // ====================================================================

    /**
     * @dev Validates if an address is a polling unit
     * @param pollingUnit Address to validate
     * @return bool True if address is a polling unit
     */
    function validateAddressAsPollingUnit(
        address pollingUnit
    ) external returns (bool);

    /**
     * @dev Validates if an address is a polling officer
     * @param pollingOfficer Address to validate
     * @return bool True if address is a polling officer
     */
    function validateAddressAsPollingOfficer(
        address pollingOfficer
    ) external returns (bool);

    // ====================================================================
    // Getter Functions - Basic Info
    // ====================================================================

    /**
     * @dev Returns the election's unique token ID
     * @return uint256 The election token ID
     */
    function getElectionUniqueTokenId() external view returns (uint256);

    /**
     * @dev Returns the address that created this election
     * @return address Creator's address
     */
    function getCreatedBy() external view returns (address);

    /**
     * @dev Returns the election name
     * @return string Election name
     */
    function getElectionName() external view returns (string memory);

    /**
     * @dev Returns the election description
     * @return string Election description
     */
    function getElectionDescription() external view returns (string memory);

    /**
     * @dev Returns the current election state
     * @return ElectionState Current state
     */
    function getElectionState() external view returns (ElectionState);

    /**
     * @dev Returns the election start timestamp
     * @return uint256 Start timestamp
     */
    function getStartTimeStamp() external view returns (uint256);

    /**
     * @dev Returns the election end timestamp
     * @return uint256 End timestamp
     */
    function getEndTimeStamp() external view returns (uint256);

    /**
     * @dev Returns the election categories
     * @return string[] Array of categories
     */
    function getElectionCategories() external view returns (string[] memory);

    // ====================================================================
    // Getter Functions - Counts
    // ====================================================================

    /**
     * @dev Returns the count of registered voters
     * @return uint256 Registered voters count
     */
    function getRegisteredVotersCount() external view returns (uint256);

    /**
     * @dev Returns the count of accredited voters
     * @return uint256 Accredited voters count
     */
    function getAccreditedVotersCount() external view returns (uint256);

    /**
     * @dev Returns the count of voters who have voted
     * @return uint256 Voted voters count
     */
    function getVotedVotersCount() external view returns (uint256);

    /**
     * @dev Returns the count of registered candidates
     * @return uint256 Candidates count
     */
    function getRegisteredCandidatesCount() external view returns (uint256);

    /**
     * @dev Returns the count of polling officers
     * @return uint256 Polling officers count
     */
    function getPollingOfficerCount() external view returns (uint256);

    /**
     * @dev Returns the count of polling units
     * @return uint256 Polling units count
     */
    function getPollingUnitCount() external view returns (uint256);

    // ====================================================================
    // Getter Functions - Arrays
    // ====================================================================

    /**
     * @dev Returns all voters in the election
     * @return ElectionVoter[] Array of all voters
     */
    function getAllVoters() external view returns (ElectionVoter[] memory);

    /**
     * @dev Returns all accredited voters
     * @return ElectionVoter[] Array of accredited voters
     */
    function getAllAccreditedVoters()
        external
        view
        returns (ElectionVoter[] memory);

    /**
     * @dev Returns all voters who have voted
     * @return ElectionVoter[] Array of voted voters
     */
    function getAllVotedVoters() external view returns (ElectionVoter[] memory);

    /**
     * @dev Returns all candidates as DTOs (without vote counts)
     * @return CandidateInfoDTO[] Array of candidate DTOs
     */
    function getAllCandidatesInDto()
        external
        view
        returns (CandidateInfoDTO[] memory);

    /**
     * @dev Returns all candidates with vote counts (only after election ends)
     * @return ElectionCandidate[] Array of candidates with vote counts
     */
    function getAllCandidates()
        external
        view
        returns (CandidateInfoDTO[] memory);

    /**
     * @dev Returns winners for each category (handles ties)
     * @return ElectionWinner[][] Array of winners per category
     */
    function getEachCategoryWinner()
        external
        view
        returns (ElectionWinner[][] memory);

    /**
     * @dev Returns polling officers addresses
     * @return address[] Array of polling officer addresses
     */
    function getPollingOfficersAddresses()
        external
        view
        returns (PollIdentifier[] memory);

    /**
     * @dev Returns polling units addresses
     * @return address[] Array of polling unit addresses
     */
    function getPollingUnitsAddresses()
        external
        view
        returns (PollIdentifier[] memory);

    // ====================================================================
    // State Management
    // ====================================================================

    /**
     * @dev Updates the election state based on current time
     */
    function updateElectionState() external;
}
