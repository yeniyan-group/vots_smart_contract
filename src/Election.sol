// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Election
 * @author Ayeni-yeniyan
 * @notice This election contract stores the election information for an election in the VutsEngine.
 * Each election is owned by the VutsEngine. It holds a createdBy field which keeps the information of the election creator
 */
contract Election is Ownable {
    // ====================================================================
    // Errors
    // ====================================================================
    error Election__UnregisteredVoterCannotBeEmpty();
    error Election__UnregisteredCandidatesCannotBeEmpty();
    error Election__InvalidStartTimeStamp();
    error Election__InvalidEndTimeStamp();
    error Election__InvalidElectionState(
        ElectionState expected,
        ElectionState actual
    );
    error Election__UnauthorizedAccountOnlyVutsEngineCanCallContract(
        address account
    );

    // ====================================================================
    // Type declarations
    // ====================================================================

    /**
     * @dev Defines the structure of our voter
     */
    struct ElectionVoter {
        string name;
        VoterState voterState;
    }

    /**
     * @dev This structure is for registering voters only
     */
    struct UnregisteredVoter {
        string name;
        string matricNo;
    }

    /**
     * @dev Structure for election candidates
     */
    struct ElectionCandidate {
        string name;
        uint256 votes;
    }

    /**
     * @dev This is for storing the unregistered candidates only
     */
    struct UnregisteredCandidate {
        string name;
        string matricNo;
        string category;
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
     * @dev Election State Enum
     */
    enum ElectionState {
        OPENED,
        STARTED,
        ENDED
    }

    /**
     * @dev Voters state Enum
     */
    enum VoterState {
        REGISTERED,
        ACCREDITED,
        VOTED
    }

    // ====================================================================
    // State variables
    // ====================================================================

    /// @dev Creator of the election
    address private immutable _createdBy;

    /// @dev The unique token identifier for this election
    uint256 private immutable _electionUniqueTokenId;

    /// @dev The startDate for this election
    uint256 private immutable _startTimeStamp;

    /// @dev The end date for this election
    uint256 private immutable _endTimeStamp;

    /// @dev The total number of registered voters
    uint256 private _registeredVotersNum;

    /// @dev The total number of accredited voters
    uint256 private _accreditedVotersNum;

    /// @dev The total number of voters who have voted
    uint256 private _votedVotersNum;

    /// @dev The total number of registered candidates
    uint256 private _registeredCandidatesNum;

    /// @dev The unique election name for this election
    string private _electionName;

    /// @dev mapping of matric number(Unique identifier) to voter
    mapping(string matricNo => ElectionVoter voter) private _votersMap;

    /// @dev map of category to candidatenames to candidate
    mapping(string categoryName => mapping(string candidateMatricNo => ElectionCandidate electionCandidates))
        private _candidatesMap;

    /// @dev Election state
    ElectionState private _electionState;

    // ====================================================================
    // Events
    // ====================================================================

    // ====================================================================
    // Modifiers
    // ====================================================================

    /**
     * @dev Ensures the function is only called when the election is started
     */
    modifier onElectionStarted() {
        _updateElectionState();
        if (_electionState != ElectionState.STARTED) {
            revert Election__InvalidElectionState(
                ElectionState.STARTED,
                _electionState
            );
        }
        _;
    }

    /**
     * @dev Ensures the function is only called when the election has ended
     */
    modifier onElectionEnded() {
        _updateElectionState();
        if (_electionState != ElectionState.ENDED) {
            revert Election__InvalidElectionState(
                ElectionState.ENDED,
                _electionState
            );
        }
        _;
    }

    // ====================================================================
    // Functions
    // ====================================================================

    /**
     * @dev Constructor to create a new election
     * @param createdBy Address of the creator
     * @param electionUniqueTokenId Unique identifier for this election
     * @param startTimeStamp Start time of the election
     * @param endTimeStamp End time of the election
     * @param electionName Name of the election
     * @param candidatesList List of candidates to register
     * @param votersList List of voters to register
     */
    constructor(
        address createdBy,
        uint256 electionUniqueTokenId,
        uint256 startTimeStamp,
        uint256 endTimeStamp,
        string memory electionName,
        UnregisteredCandidate[] memory candidatesList,
        UnregisteredVoter[] memory votersList
    ) Ownable(msg.sender) {
        if (block.timestamp <= startTimeStamp) {
            revert Election__InvalidStartTimeStamp();
        }
        if (endTimeStamp <= startTimeStamp) {
            revert Election__InvalidEndTimeStamp();
        }
        _createdBy = createdBy;
        _electionUniqueTokenId = electionUniqueTokenId;
        _electionName = electionName;

        _startTimeStamp = startTimeStamp;
        _endTimeStamp = endTimeStamp;

        _electionState = ElectionState.OPENED;

        _registerCandidates(candidatesList);
        _registerVoters(votersList);
    }

    // external functions

    // public functions

    // internal functions

    /**
     * @dev Updates the election state based on current timestamp
     */
    function _updateElectionState() internal {
        uint256 currentTs = block.timestamp;
        if (
            currentTs >= _startTimeStamp &&
            currentTs < _endTimeStamp &&
            _electionState != ElectionState.STARTED
        ) {
            _electionState = ElectionState.STARTED;
        }
        if (currentTs >= _endTimeStamp) {
            _electionState = ElectionState.ENDED;
        }
    }

    /**
     * @dev Override function to check owner with custom error
     */
    function _checkOwner() internal view override {
        if (owner() != _msgSender()) {
            revert Election__UnauthorizedAccountOnlyVutsEngineCanCallContract(
                _msgSender()
            );
        }
    }

    /**
     * @dev Registers voters from the provided list
     * @param votersList Array of unregistered voters to register
     */
    function _registerVoters(
        UnregisteredVoter[] memory votersList
    ) internal onlyOwner {
        if (votersList.length < 1) {
            revert Election__UnregisteredVoterCannotBeEmpty();
        }
        // add all voters to votersList
        for (uint i = 0; i < votersList.length; i++) {
            UnregisteredVoter memory voter = votersList[i];
            // create an electionVoter from voter
            ElectionVoter memory registeredVoter = ElectionVoter({
                name: voter.name,
                voterState: VoterState.REGISTERED
            });
            // add to votersList
            _votersMap[voter.matricNo] = registeredVoter;
        }
        _registeredVotersNum = votersList.length;
    }

    /**
     * @dev Registers candidates from the provided list
     * @param candidatesList Array of unregistered candidates to register
     */
    function _registerCandidates(
        UnregisteredCandidate[] memory candidatesList
    ) internal onlyOwner {
        if (candidatesList.length < 1) {
            revert Election__UnregisteredCandidatesCannotBeEmpty();
        }
        // add all Candidates to _candidateMap
        for (uint i = 0; i < candidatesList.length; i++) {
            UnregisteredCandidate memory voter = candidatesList[i];
            // create an ElectionCandidate from candidate
            ElectionCandidate memory registeredCandidate = ElectionCandidate({
                name: voter.name,
                votes: 0
            });
            // add to votersList
            _candidatesMap[voter.category][
                voter.matricNo
            ] = registeredCandidate;
        }
        _registeredCandidatesNum = candidatesList.length;
    }

    // private functions

    // view & pure functions
}

// Election owner
// Election owner picks the election start time and end time and format
// Registration officer address
// Registration officers can register users by associating their address with users
// Check if user is valid
// Accredited voters can vote only
// Can view all voters
// Can check accredited voters
// Check if election is open
// Close election How should the previous result be stored?
// Election name
// Each election is a controct. When it is finished it can no longer be changed. Once done it is done
// Election start, OPEN_FOR_REGISTRATION, OPEN_FOR_VOTING, CLOSED
