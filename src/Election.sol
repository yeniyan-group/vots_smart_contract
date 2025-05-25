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
pragma solidity ^0.8.21;

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
    error Election__VoterInfoDTOCannotBeEmpty();
    error Election__UnregisteredVoterCannotBeAccredited();
    error Election__OnlyPollingUnitAllowed();
    error Election__OnlyPollingOfficerAllowed();
    error Election__AddressCanOnlyHaveOneRole();
    error Election__CandidatesInfoDTOCannotBeEmpty();
    error Election__AllCategoriesMustHaveOnlyOneVotedCandidate();
    error Election__InvalidStartTimeStamp();
    error Election__InvalidEndTimeStamp();
    error Election__InvalidElectionState(
        ElectionState expected,
        ElectionState actual
    );
    error Election__UnauthorizedAccountOnlyVutsEngineCanCallContract(
        address account
    );
    error Election__VoterCannotBeValidated();
    error Election__VoterAlreadyVoted();
    error Election__VoterAlreadyAccredited();
    error Election__UnknownVoter(string matricNo);
    error Election__UnaccreditedVoter(string matricNo);
    error Election__PollingOfficerAndUnitCannotBeEmpty();
    error Election__DuplicateVoter(string matricNo);
    error Election__DuplicateCandidate(string matricNo);
    error Election__DuplicateCategory();
    error Election__InvalidCategory(string categoryName);

    // ====================================================================
    // Type declarations
    // ====================================================================

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
        UNKNOWN,
        REGISTERED,
        ACCREDITED,
        VOTED
    }
    /**
     * @dev Voters state Enum
     */
    enum CandidateState {
        UNKNOWN,
        REGISTERED
    }

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
    struct VoterInfoDTO {
        string name;
        string matricNo;
    }

    /**
     * @dev Structure for election candidates
     */
    struct ElectionCandidate {
        string name;
        uint256 votes;
        CandidateState state;
    }

    /**
     * @dev This is for storing the unregistered candidates only
     */
    struct CandidateInfoDTO {
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
    string[] private _registeredVotersList;

    /// @dev The total number of accredited voters
    uint256 private _accreditedVotersCount;

    /// @dev The total number of voters who have voted
    uint256 private _votedVotersCount;

    /// @dev The total number of accredited voters
    uint256 private _pollingOfficerCount;

    /// @dev The total number of voters who have voted
    uint256 private _pollintUnitCount;

    /// @dev List of registered candidates
    string[] private _registeredCandidatesList;

    /// @dev The unique election name for this election
    string private _electionName;

    /// @dev mapping of matric number(Unique identifier) to voter
    mapping(string matricNo => ElectionVoter voter) private _votersMap;

    /// @dev map of category to candidatenames to candidate
    mapping(string categoryName => mapping(string candidateMatricNo => ElectionCandidate electionCandidates))
        private _candidatesMap;

    /// @dev mapping of valid polling addresses
    mapping(address pollingAddress => bool isValid)
        private _allowedPollingUnits;

    /// @dev mapping of valid polling officer addresses
    mapping(address pollingOfficerAddress => bool isValid)
        private _allowedPollingOfficers;

    /// @dev List of all the categories in this election
    string[] private _electionCategories;

    /// @dev Election state
    ElectionState private _electionState;

    // ====================================================================
    // Events
    // ====================================================================
    event AccreditedVoter(string matricNo);
    event VoterVoted();

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

    modifier pollingUnitOnly(address pollingUnitAddress) {
        if (!_allowedPollingUnits[pollingUnitAddress]) {
            revert Election__OnlyPollingUnitAllowed();
        }
        _;
    }

    modifier pollingOfficerOnly(address pollingOfficerAddress) {
        if (!_allowedPollingOfficers[pollingOfficerAddress]) {
            revert Election__OnlyPollingOfficerAllowed();
        }
        _;
    }

    modifier noUnknown(string memory matricNo) {
        if (_votersMap[matricNo].voterState == VoterState.UNKNOWN) {
            revert Election__UnknownVoter(matricNo);
        }
        _;
    }

    modifier accreditedVoterOnly(string memory matricNo) {
        if (_votersMap[matricNo].voterState == VoterState.VOTED) {
            revert Election__VoterAlreadyVoted();
        }
        if (_votersMap[matricNo].voterState != VoterState.ACCREDITED) {
            revert Election__UnaccreditedVoter(matricNo);
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
        CandidateInfoDTO[] memory candidatesList,
        VoterInfoDTO[] memory votersList,
        address[] memory pollingUnitAddresses,
        address[] memory pollingOfficerAddresses,
        string[] memory electionCategories
    ) Ownable(msg.sender) {
        if (block.timestamp >= startTimeStamp) {
            revert Election__InvalidStartTimeStamp();
        }
        if (startTimeStamp >= endTimeStamp) {
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
        _registerOfficersAndUnits({
            pollingOfficerAddresses: pollingOfficerAddresses,
            pollingUnitAddresses: pollingUnitAddresses
        });
        _validateCategories(electionCategories);
    }

    // ====================================================================
    // External functions
    // ====================================================================

    // ====================================================================
    // Public functions
    // ====================================================================

    /**
     * @dev Returns Returns a list of all voters
     */
    function getAllVoters() public view returns (ElectionVoter[] memory) {
        ElectionVoter[] memory all = new ElectionVoter[](
            _registeredVotersList.length
        );
        for (uint i = 0; i < _registeredVotersList.length; i++) {
            all[i] = _votersMap[_registeredVotersList[i]];
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all accredited voters
     */
    function getAllAccreditedVoters()
        public
        view
        returns (ElectionVoter[] memory)
    {
        uint256 voterCount;
        ElectionVoter[] memory all = new ElectionVoter[](
            _accreditedVotersCount
        );
        for (uint i = 0; i < _registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[_registeredVotersList[i]];
            if (voter.voterState == VoterState.ACCREDITED) {
                all[voterCount] = voter;
                voterCount++;
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Voted voters
     */
    function getAllVotedVoters() public view returns (ElectionVoter[] memory) {
        uint256 voterCount;
        ElectionVoter[] memory all = new ElectionVoter[](_votedVotersCount);
        for (uint i = 0; i < _registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[_registeredVotersList[i]];
            if (voter.voterState == VoterState.VOTED) {
                all[voterCount] = voter;
                voterCount++;
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Candidates
     */
    function getAllCandidatesInDto()
        public
        view
        returns (CandidateInfoDTO[] memory)
    {
        uint256 candidateCount;
        CandidateInfoDTO[] memory all = new CandidateInfoDTO[](
            _registeredCandidatesList.length
        );
        for (uint i = 0; i < _electionCategories.length; i++) {
            for (uint j = 0; j < _registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[
                    _electionCategories[i]
                ][_registeredCandidatesList[j]];
                if (candidate.state == CandidateState.REGISTERED) {
                    all[candidateCount] = CandidateInfoDTO({
                        name: candidate.name,
                        matricNo: _registeredCandidatesList[j],
                        category: _electionCategories[i]
                    });
                    candidateCount++;
                }
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Candidates
     */
    function getAllCandidates()
        public
        onElectionEnded
        returns (ElectionCandidate[] memory)
    {
        uint256 candidateCount;
        ElectionCandidate[] memory all = new ElectionCandidate[](
            _registeredCandidatesList.length
        );
        for (uint i = 0; i < _electionCategories.length; i++) {
            for (uint j = 0; j < _registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[
                    _electionCategories[i]
                ][_registeredCandidatesList[j]];
                if (candidate.state == CandidateState.REGISTERED) {
                    all[candidateCount] = candidate;
                    candidateCount++;
                }
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Candidates
     */
    function getEachCategoryWinner()
        public
        onElectionEnded
        returns (ElectionWinner[][] memory)
    {
        // Assign to _electionCategories.length.
        // We will be returning a list containing a list
        // that holds the candidate that won since it is possible to tie
        ElectionWinner[][] memory allWinners = new ElectionWinner[][](
            _electionCategories.length
        );
        for (uint i = 0; i < _electionCategories.length; i++) {
            string memory category = _electionCategories[i];
            uint256 maxVotes;
            uint256 winnerCount;

            // Find the maxVote for this category
            for (uint j = 0; j < _registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[category][
                    _registeredCandidatesList[j]
                ];
                if (
                    candidate.state == CandidateState.REGISTERED &&
                    candidate.votes > maxVotes
                ) {
                    maxVotes = candidate.votes;
                }
            }
            // Count winners with max votes
            if (maxVotes > 0) {
                for (uint j = 0; j < _registeredCandidatesList.length; j++) {
                    ElectionCandidate memory candidate = _candidatesMap[
                        category
                    ][_registeredCandidatesList[j]];
                    if (
                        candidate.state == CandidateState.REGISTERED &&
                        candidate.votes == maxVotes
                    ) {
                        winnerCount++;
                    }
                }
                // Collect all winners
                ElectionWinner[] memory categoryWinners = new ElectionWinner[](
                    winnerCount
                );
                uint256 currentWinnerIndex;
                for (uint j = 0; j < _registeredCandidatesList.length; j++) {
                    string memory candidateMatricNo = _registeredCandidatesList[
                        j
                    ];
                    ElectionCandidate memory candidate = _candidatesMap[
                        category
                    ][candidateMatricNo];

                    if (
                        candidate.state == CandidateState.REGISTERED &&
                        candidate.votes == maxVotes
                    ) {
                        categoryWinners[currentWinnerIndex] = ElectionWinner({
                            matricNo: candidateMatricNo,
                            electionCandidate: candidate,
                            category: category
                        });
                        currentWinnerIndex++;
                    }
                }
                allWinners[i] = categoryWinners;
            } else {
                // No votes cast in this category
                allWinners[i] = new ElectionWinner[](0);
            }
        }
        return allWinners;
    }

    /**
     * @dev Returns the address of the election creator
     * @return address Creator's address
     */
    function getCreatedBy() public view returns (address) {
        return _createdBy;
    }

    /**
     * @dev Returns the unique token identifier for this election
     * @return uint256 Election unique token ID
     */
    function getElectionUniqueTokenId() public view returns (uint256) {
        return _electionUniqueTokenId;
    }

    /**
     * @dev Returns the start timestamp for this election
     * @return uint256 Start timestamp
     */
    function getStartTimeStamp() public view returns (uint256) {
        return _startTimeStamp;
    }

    /**
     * @dev Returns the end timestamp for this election
     * @return uint256 End timestamp
     */
    function getEndTimeStamp() public view returns (uint256) {
        return _endTimeStamp;
    }

    /**
     * @dev Returns the name of this election
     * @return string Election name
     */
    function getElectionName() public view returns (string memory) {
        return _electionName;
    }

    /**
     * @dev Returns the current state of the election
     * @return ElectionState Current election state
     */
    function getElectionState() public view returns (ElectionState) {
        // Create a storage variable to hold the current state
        ElectionState currentState = _electionState;

        // Check if state needs updating based on current time
        uint256 currentTs = block.timestamp;
        if (
            currentTs >= _startTimeStamp &&
            currentTs < _endTimeStamp &&
            currentState != ElectionState.STARTED
        ) {
            currentState = ElectionState.STARTED;
        }
        if (currentTs >= _endTimeStamp) {
            currentState = ElectionState.ENDED;
        }

        return currentState;
    }

    /**
     * @dev Returns the total number of registered voters
     * @return uint256 Number of registered voters
     */
    function getRegisteredVotersCount() public view returns (uint256) {
        return _registeredVotersList.length;
    }

    /**
     * @dev Returns the total number of accredited voters
     * @return uint256 Number of accredited voters
     */
    function getAccreditedVotersCount() public view returns (uint256) {
        return _accreditedVotersCount;
    }

    /**
     * @dev Returns the total number of voters who have voted
     * @return uint256 Number of voters who have voted
     */
    function getVotedVotersCount() public view returns (uint256) {
        return _votedVotersCount;
    }

    /**
     * @dev Returns the total number of polling officers
     * @return uint256 Number of polling officers
     */
    function getPollingOfficerCount() public view returns (uint256) {
        return _pollingOfficerCount;
    }

    /**
     * @dev Returns the total number of polling units
     * @return uint256 Number of polling units
     */
    function getPollingUnitCount() public view returns (uint256) {
        return _pollintUnitCount;
    }

    /**
     * @dev Returns the total number of registered candidates
     * @return uint256 Number of registered candidates
     */
    function getRegisteredCandidatesCount() public view returns (uint256) {
        return _registeredCandidatesList.length;
    }

    /**
     * @dev Accredits a voter with valid matric number
     * @param voterMatricNo The matric number of the voter
     * @param pollingOfficerAddress Address of the polling officer
     */
    function accrediteVoter(
        string memory voterMatricNo,
        address pollingOfficerAddress
    )
        public
        onlyOwner
        pollingOfficerOnly(pollingOfficerAddress)
        onElectionStarted
        noUnknown(voterMatricNo)
    {
        if (_votersMap[voterMatricNo].voterState == VoterState.ACCREDITED) {
            revert Election__VoterAlreadyAccredited();
        }
        _votersMap[voterMatricNo].voterState = VoterState.ACCREDITED;
        _accreditedVotersCount++;
        emit AccreditedVoter(voterMatricNo);
    }

    /**
     * @dev Allows an accredited voter to vote for candidates
     * @param voterMatricNo The matric number of the voter
     * @param voterName The name of the voter for validation
     * @param pollingUnitAddress Address of the polling unit
     * @param candidatesList List of candidates being voted for
     */
    function voteCandidates(
        string memory voterMatricNo,
        string memory voterName,
        address pollingUnitAddress,
        CandidateInfoDTO[] memory candidatesList
    )
        public
        onlyOwner
        pollingUnitOnly(pollingUnitAddress)
        onElectionStarted
        noUnknown(voterMatricNo)
        accreditedVoterOnly(voterMatricNo)
    {
        if (candidatesList.length < 1) {
            revert Election__CandidatesInfoDTOCannotBeEmpty();
        }
        if (candidatesList.length != _electionCategories.length) {
            revert Election__AllCategoriesMustHaveOnlyOneVotedCandidate();
        }
        if (!compareStrings(voterName, _votersMap[voterMatricNo].name)) {
            revert Election__VoterCannotBeValidated();
        }
        for (uint i = 0; i < candidatesList.length; i++) {
            CandidateInfoDTO memory candidate = candidatesList[i];
            if (!_isValidCategory(candidate.category)) {
                revert Election__InvalidCategory(candidate.category);
            }
            _candidatesMap[candidate.category][candidate.matricNo].votes++;
        }
        _votersMap[voterMatricNo].voterState = VoterState.VOTED;
        _votedVotersCount++;
        emit VoterVoted();
    }

    /**
     * @dev Updates the election state based on current time
     */
    function updateElectionState() public {
        _updateElectionState();
    }

    // ====================================================================
    // Internal functions
    // ====================================================================

    /**
     * @dev Checks if the categoryName is valid
     */
    function _isValidCategory(
        string memory categoryName
    ) internal view returns (bool) {
        for (uint i = 0; i < _electionCategories.length; i++) {
            if (compareStrings(categoryName, _electionCategories[i])) {
                return true;
            }
        }
        return false;
    }

    function _containsDuplicateCategory(
        string[] memory votedCategories,
        string memory newCategory
    ) internal pure returns (bool) {
        for (uint i = 0; i < votedCategories.length; i++) {
            if (compareStrings(newCategory, votedCategories[i])) {
                return true;
            }
        }
        return false;
    }

    function _validateCategories(string[] memory votedCategories) internal {
        for (uint i = 0; i < votedCategories.length; i++) {
            if (
                _containsDuplicateCategory(
                    _electionCategories,
                    votedCategories[i]
                )
            ) {
                revert Election__DuplicateCategory();
            } else {
                _electionCategories.push(votedCategories[i]);
            }
        }
    }

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
        VoterInfoDTO[] memory votersList
    ) internal onlyOwner {
        if (votersList.length < 1) {
            revert Election__VoterInfoDTOCannotBeEmpty();
        }
        // add all voters to votersList
        for (uint i = 0; i < votersList.length; i++) {
            VoterInfoDTO memory voter = votersList[i];
            // create an electionVoter from voter
            ElectionVoter memory registeredVoter = ElectionVoter({
                name: voter.name,
                voterState: VoterState.REGISTERED
            });
            // add to votersList if the state is unknown
            if (_votersMap[voter.matricNo].voterState == VoterState.UNKNOWN) {
                _votersMap[voter.matricNo] = registeredVoter;
            } else {
                revert Election__DuplicateVoter(voter.matricNo);
            }
            _registeredVotersList.push(voter.matricNo);
        }
    }

    /**
     * @dev Registers candidates from the provided list
     * @param candidatesList Array of unregistered candidates to register
     */
    function _registerCandidates(
        CandidateInfoDTO[] memory candidatesList
    ) internal onlyOwner {
        if (candidatesList.length < 1) {
            revert Election__CandidatesInfoDTOCannotBeEmpty();
        }
        // add all Candidates to _candidateMap
        for (uint i = 0; i < candidatesList.length; i++) {
            CandidateInfoDTO memory candidate = candidatesList[i];
            // create an ElectionCandidate from candidate
            ElectionCandidate memory registeredCandidate = ElectionCandidate({
                name: candidate.name,
                votes: 0,
                state: CandidateState.REGISTERED
            });
            if (
                _candidatesMap[candidate.category][candidate.matricNo].state ==
                CandidateState.UNKNOWN
            ) {
                // add to votersList
                _candidatesMap[candidate.category][
                    candidate.matricNo
                ] = registeredCandidate;
            } else {
                revert Election__DuplicateCandidate(candidate.matricNo);
            }
            _registeredCandidatesList.push(candidate.matricNo);
        }
    }

    /**
     * @dev Registers polling officers and polling units
     * @param pollingOfficerAddresses Array of polling officer addresses
     * @param pollingUnitAddresses Array of polling unit addresses
     */
    function _registerOfficersAndUnits(
        address[] memory pollingOfficerAddresses,
        address[] memory pollingUnitAddresses
    ) internal onlyOwner {
        if (
            pollingOfficerAddresses.length < 1 ||
            pollingUnitAddresses.length < 1
        ) {
            revert Election__PollingOfficerAndUnitCannotBeEmpty();
        }

        for (uint i = 0; i < pollingOfficerAddresses.length; i++) {
            address officerAddress = pollingOfficerAddresses[i];
            if (officerAddress == _createdBy) {
                revert Election__AddressCanOnlyHaveOneRole();
            }
            _allowedPollingOfficers[officerAddress] = true;
        }
        for (uint i = 0; i < pollingUnitAddresses.length; i++) {
            address unitAddress = pollingUnitAddresses[i];
            if (
                unitAddress == _createdBy ||
                _allowedPollingOfficers[unitAddress]
            ) {
                revert Election__AddressCanOnlyHaveOneRole();
            }
            _allowedPollingUnits[unitAddress] = true;
        }

        _pollingOfficerCount = pollingOfficerAddresses.length;
        _pollintUnitCount = pollingUnitAddresses.length;
    }

    /**
     * @dev Compares two strings by comparing their keccak256 hashes
     * @param first First string to compare
     * @param second Second string to compare
     * @return bool True if strings are equal, false otherwise
     */
    function compareStrings(
        string memory first,
        string memory second
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(first)) ==
            keccak256(abi.encodePacked(second));
    }
}
