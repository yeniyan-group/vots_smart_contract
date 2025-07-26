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
import {IElection} from "./interfaces/IElection.sol";
import {FunctionsClient} from "chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {strings} from "lib/solidity-stringutils/src/strings.sol";

/**
 * @title Election
 * @author Ayeni-yeniyan
 * @notice This election contract stores the election information for an election in the VotsEngine.
 * Each election is owned by the VotsEngine. It holds a createdBy field which keeps the information of the election creator
 */
contract Election is IElection, Ownable {
    using strings for *;
    // ====================================================================
    // Errors
    // ====================================================================
    error Election__VoterInfoDTOCannotBeEmpty();
    error Election__UnregisteredVoterCannotBeAccredited();
    error Election__OnlyPollingUnitAllowed(address errorAddress);
    error Election__OnlyPollingOfficerAllowed(address errorAddress);
    error Election__AddressCanOnlyHaveOneRole();
    error Election__PollingOfficerOrUnitNameEmpty();
    error Election__CandidatesInfoDTOCannotBeEmpty();
    error Election__AllCategoriesMustHaveOnlyOneVotedCandidate();
    error Election__InvalidStartTimeStamp();
    error Election__InvalidEndTimeStamp();
    error Election__InvalidElectionState(
        ElectionState expected,
        ElectionState actual
    );
    error Election__VoterInfoListAboveBatchLimit(
        uint256 expected,
        uint256 actual
    );
    error Election__UnauthorizedAccountOnlyVotsEngineCanCallContract(
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
    error Election__InvalidVote();
    error Election__RegisterCategoriesMustBeCalledBeforeRegisterVoters();
    error Election__VotersAlreadyRegistered();
    error Election__OnlyElectionCreatorAllowed();
    error Election__InvalidCategory(string categoryName);

    // ====================================================================
    // State variables
    // ====================================================================

    /// @dev Creator of the election
    address private immutable i_createdBy;

    /// @dev Limit of voters that can be registered at a time
    uint256 private constant VOTERS_BATCH_LIMIT = 100;

    /// @dev The unique token identifier for this election
    uint256 private immutable i_electionUniqueTokenId;

    /// @dev The startDate for this election
    uint256 private immutable i_startTimeStamp;

    /// @dev The end date for this election
    uint256 private immutable i_endTimeStamp;

    /// @dev The total number of registered voters
    string[] private s_registeredVotersList;

    /// @dev The total number of accredited voters
    uint256 private s_accreditedVotersCount;

    /// @dev The total number of voters who have voted
    uint256 private s_votedVotersCount;

    /// @dev List of registered candidates
    string[] private s_registeredCandidatesList;

    /// @dev The unique election name for this election
    string private s_electionName;

    /// @dev mapping of matric number(Unique identifier) to voter
    mapping(string matricNo => ElectionVoter voter) private _votersMap;

    /// @dev map of category to candidatenames to candidate
    mapping(string categoryName => mapping(string candidateMatricNo => ElectionCandidate electionCandidates))
        private _candidatesMap;

    /// @dev mapping of valid polling addresses
    mapping(address pollingAddress => bool isValid)
        private _allowedPollingUnits;

    /// Store polling officer addresses
    PollIdentifier[] private s_pollingOfficersAddressList;

    /// Store polling unit addresses
    PollIdentifier[] private s_pollingUnitsAddressList;

    /// @dev mapping of valid polling officer addresses
    mapping(address pollingOfficerAddress => bool isValid)
        private _allowedPollingOfficers;

    /// @dev List of all the categories in this election
    string[] private _electionCategories;

    /// @dev Map of validCategories
    mapping(string category => bool isValid) s_validCategories;

    /// @dev Election state
    ElectionState private _electionState;

    string private s_description;

    // ====================================================================
    // Events
    // ====================================================================
    event AccreditedVoter(string matricNo);
    event VoterVoted();
    event ValidateAddressResult(bool result);

    // ====================================================================
    // Modifiers
    // ====================================================================

    /**
     * @dev Ensures the function is only called when before election is started
     */
    modifier beforeElectionStarted() {
        if (block.timestamp > i_startTimeStamp) {
            revert Election__InvalidElectionState(
                ElectionState.OPENED,
                _electionState
            );
        }
        _;
    }

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
        // _updateElectionState();
        if (block.timestamp < i_endTimeStamp) {
            revert Election__InvalidElectionState(
                ElectionState.ENDED,
                _electionState
            );
        }
        _;
    }

    modifier pollingUnitOnly(address pollingUnitAddress) {
        if (!_allowedPollingUnits[pollingUnitAddress]) {
            revert Election__OnlyPollingUnitAllowed(pollingUnitAddress);
        }
        _;
    }

    modifier pollingOfficerOnly(address pollingOfficerAddress) {
        if (!_allowedPollingOfficers[pollingOfficerAddress]) {
            revert Election__OnlyPollingOfficerAllowed(pollingOfficerAddress);
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

    modifier onlyElectionCreator(address creator) {
        if (creator != i_createdBy) {
            revert Election__OnlyElectionCreatorAllowed();
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
     * @param params Election params
     */
    constructor(
        address createdBy,
        uint256 electionUniqueTokenId,
        ElectionParams memory params
    ) Ownable(msg.sender) {
        if (block.timestamp >= params.startTimeStamp) {
            revert Election__InvalidStartTimeStamp();
        }
        if (params.startTimeStamp >= params.endTimeStamp) {
            revert Election__InvalidEndTimeStamp();
        }
        i_createdBy = createdBy;
        i_electionUniqueTokenId = electionUniqueTokenId;
        s_electionName = params.electionName;
        s_description = params.description;

        i_startTimeStamp = params.startTimeStamp;
        i_endTimeStamp = params.endTimeStamp;

        _electionState = ElectionState.OPENED;

        _validateCategories(params.electionCategories);
        _registerCandidates(params.candidatesList);
        _registerOfficersAndUnits({
            pollingOfficerAddresses: params.pollingOfficers,
            pollingUnitAddresses: params.pollingUnits
        });
    }

    // ====================================================================
    // Public functions
    // ====================================================================
    /**
     * @dev Validates a voter for voting
     * @param name the first word of the fullname
     * @param matricNo Matric number of the voter
     * @param pollingUnitAddress Address of the polling unit
     * @return validAddress True if the voter is valid, false otherwise
     */
    function validateVoterForVoting(
        string memory name,
        string memory matricNo,
        address pollingUnitAddress
    )
        public
        pollingUnitOnly(pollingUnitAddress)
        noUnknown(matricNo)
        onElectionStarted
        accreditedVoterOnly(matricNo)
        onlyOwner
        returns (bool validAddress)
    {
        _updateElectionState();
        ElectionVoter memory voter = _votersMap[matricNo];
        emit ValidateAddressResult(validAddress);
        string memory voterLastName = getfirstWord(voter.name);
        bool isValidVoter = compareStrings(voterLastName, name) &&
            voter.voterState == VoterState.ACCREDITED;
        if (!isValidVoter) {
            revert Election__VoterCannotBeValidated();
        }
        return isValidVoter;
    }

    function validateAddressAsPollingUnit(
        address pollingUnitAddress
    )
        public
        pollingUnitOnly(pollingUnitAddress)
        onlyOwner
        returns (bool validAddress)
    {
        _updateElectionState();
        validAddress = _allowedPollingUnits[pollingUnitAddress];
        emit ValidateAddressResult(validAddress);
    }

    function validateAddressAsPollingOfficer(
        address pollingUnitAddress
    )
        public
        pollingOfficerOnly(pollingUnitAddress)
        onlyOwner
        returns (bool validAddress)
    {
        _updateElectionState();
        validAddress = _allowedPollingOfficers[pollingUnitAddress];
        emit ValidateAddressResult(validAddress);
    }

    /**
     * @dev Returns Returns a list of all voters
     */
    function getAllVoters() public view returns (ElectionVoter[] memory) {
        ElectionVoter[] memory all = new ElectionVoter[](
            s_registeredVotersList.length
        );
        for (uint256 i = 0; i < s_registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[s_registeredVotersList[i]];
            all[i] = ElectionVoter({
                name: voter.name,
                level: voter.level,
                department: voter.department,
                voterState: VoterState.REGISTERED
            });
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all accredited voters
     */
    function getAllAccreditedVoters()
        public
        view
        onElectionEnded
        returns (ElectionVoter[] memory)
    {
        uint256 voterCount;
        ElectionVoter[] memory all = new ElectionVoter[](
            s_accreditedVotersCount
        );
        for (uint256 i = 0; i < s_registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[s_registeredVotersList[i]];
            if (
                voter.voterState == VoterState.ACCREDITED ||
                voter.voterState == VoterState.VOTED
            ) {
                all[voterCount] = voter;
                voterCount++;
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Voted voters
     */
    function getAllVotedVoters()
        public
        view
        onElectionEnded
        returns (ElectionVoter[] memory)
    {
        uint256 voterCount;
        ElectionVoter[] memory all = new ElectionVoter[](s_votedVotersCount);
        for (uint256 i = 0; i < s_registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[s_registeredVotersList[i]];
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
            s_registeredCandidatesList.length
        );
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            for (uint256 j = 0; j < s_registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[
                    _electionCategories[i]
                ][s_registeredCandidatesList[j]];
                if (candidate.state == CandidateState.REGISTERED) {
                    all[candidateCount] = CandidateInfoDTO({
                        name: candidate.name,
                        matricNo: s_registeredCandidatesList[j],
                        category: _electionCategories[i],
                        voteFor: 0,
                        voteAgainst: 0
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
        view
        onElectionEnded
        returns (CandidateInfoDTO[] memory)
    {
        // uint256 candidateCount;
        // ElectionCandidate[] memory all = new ElectionCandidate[](
        //      s_registeredCandidatesList.length
        // );
        // for (uint256 i = 0; i < _electionCategories.length; i++) {
        //     for (uint256 j = 0; j <  s_registeredCandidatesList.length; j++) {
        //         ElectionCandidate memory candidate = _candidatesMap[
        //             _electionCategories[i]
        //         ][ s_registeredCandidatesList[j]];
        //         if (candidate.state == CandidateState.REGISTERED) {
        //             all[candidateCount] = candidate;
        //             candidateCount++;
        //         }
        //     }
        // }
        // return all;
        uint256 candidateCount;
        CandidateInfoDTO[] memory all = new CandidateInfoDTO[](
            s_registeredCandidatesList.length
        );
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            for (uint256 j = 0; j < s_registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[
                    _electionCategories[i]
                ][s_registeredCandidatesList[j]];
                if (candidate.state == CandidateState.REGISTERED) {
                    all[candidateCount] = CandidateInfoDTO({
                        name: candidate.name,
                        matricNo: s_registeredCandidatesList[j],
                        category: _electionCategories[i],
                        voteFor: candidate.votes,
                        voteAgainst: candidate.votesAgainst
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
    function getEachCategoryWinner()
        public
        view
        onElectionEnded
        returns (ElectionWinner[][] memory)
    {
        // Assign to _electionCategories.length.
        // We will be returning a list containing a list
        // that holds the candidate that won since it is possible to tie
        ElectionWinner[][] memory allWinners = new ElectionWinner[][](
            _electionCategories.length
        );
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            string memory category = _electionCategories[i];
            uint256 maxVotes;
            uint256 winnerCount;

            // Find the maxVote for this category
            for (uint256 j = 0; j < s_registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[category][
                    s_registeredCandidatesList[j]
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
                for (
                    uint256 j = 0;
                    j < s_registeredCandidatesList.length;
                    j++
                ) {
                    ElectionCandidate memory candidate = _candidatesMap[
                        category
                    ][s_registeredCandidatesList[j]];
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
                for (
                    uint256 j = 0;
                    j < s_registeredCandidatesList.length;
                    j++
                ) {
                    string
                        memory candidateMatricNo = s_registeredCandidatesList[
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
        return i_createdBy;
    }

    /**
     * @dev Returns the description of the election
     * @return Election description
     */
    function getElectionDescription() public view returns (string memory) {
        return s_description;
    }

    /**
     * @dev Returns the unique token identifier for this election
     * @return uint256 Election unique token ID
     */
    function getElectionUniqueTokenId() public view returns (uint256) {
        return i_electionUniqueTokenId;
    }

    /**
     * @dev Returns the start timestamp for this election
     * @return uint256 Start timestamp
     */
    function getStartTimeStamp() public view returns (uint256) {
        return i_startTimeStamp;
    }

    /**
     * @dev Returns the end timestamp for this election
     * @return uint256 End timestamp
     */
    function getEndTimeStamp() public view returns (uint256) {
        return i_endTimeStamp;
    }

    /**
     * @dev Returns the name of this election
     * @return string Election name
     */
    function getElectionName() public view returns (string memory) {
        return s_electionName;
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
            currentTs >= i_startTimeStamp &&
            currentTs < i_endTimeStamp &&
            currentState != ElectionState.STARTED
        ) {
            currentState = ElectionState.STARTED;
        }
        if (currentTs >= i_endTimeStamp) {
            currentState = ElectionState.ENDED;
        }

        return currentState;
    }

    /**
     * @dev Returns the total number of registered voters
     * @return uint256 Number of registered voters
     */
    function getRegisteredVotersCount() public view returns (uint256) {
        return s_registeredVotersList.length;
    }

    /**
     * @dev Returns the total number of accredited voters
     * @return uint256 Number of accredited voters
     */
    function getAccreditedVotersCount() public view returns (uint256) {
        return s_accreditedVotersCount;
    }

    /**
     * @dev Returns the total number of voters who have voted
     * @return uint256 Number of voters who have voted
     */
    function getVotedVotersCount() public view returns (uint256) {
        return s_votedVotersCount;
    }

    /**
     * @dev Returns the total number of polling officers
     * @return uint256 Number of polling officers
     */
    function getPollingOfficerCount() public view returns (uint256) {
        return s_pollingOfficersAddressList.length;
    }

    /**
     * @dev Returns the total number of polling units
     * @return uint256 Number of polling units
     */
    function getPollingUnitCount() public view returns (uint256) {
        return s_pollingUnitsAddressList.length;
    }

    /**
     * @dev Returns the address of polling officers
     * @return uint256 Number of polling officers
     */
    function getPollingOfficersAddresses()
        public
        view
        returns (PollIdentifier[] memory)
    {
        // PollIdentifier[] memory pollingOfficersAddressList = new PollIdentifier[](
        //      s_pollingOfficersAddressList.length
        // );
        return s_pollingOfficersAddressList;
    }

    /**
     * @dev Returns the address of polling units
     * @return uint256 Number of polling units
     */
    function getPollingUnitsAddresses()
        public
        view
        returns (PollIdentifier[] memory)
    {
        return s_pollingUnitsAddressList;
    }

    /**
     * @dev Returns the total number of registered candidates
     * @return uint256 Number of registered candidates
     */
    function getRegisteredCandidatesCount() public view returns (uint256) {
        return s_registeredCandidatesList.length;
    }

    function getElectionCategories() public view returns (string[] memory) {
        return _electionCategories;
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
        // Add explicit logging for debugging
        VoterState currentState = _votersMap[voterMatricNo].voterState;
        // if voter is voted or accredited revert
        if (currentState == VoterState.ACCREDITED) {
            revert Election__VoterAlreadyAccredited();
        }
        if (currentState == VoterState.VOTED) {
            revert Election__VoterAlreadyVoted();
        }
        _votersMap[voterMatricNo].voterState = VoterState.ACCREDITED;
        s_accreditedVotersCount++;
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

        string memory voterLastName = getfirstWord(
            _votersMap[voterMatricNo].name
        );
        if (!compareStrings(voterName, voterLastName)) {
            revert Election__VoterCannotBeValidated();
        }
        for (uint256 i = 0; i < candidatesList.length; i++) {
            CandidateInfoDTO memory candidate = candidatesList[i];
            if (!_isValidCategory(candidate.category)) {
                revert Election__InvalidCategory(candidate.category);
            }
            if (candidate.voteFor == candidate.voteAgainst) {
                revert Election__InvalidVote();
            }
            if (candidate.voteFor > candidate.voteAgainst) {
                _candidatesMap[candidate.category][candidate.matricNo].votes++;
            } else {
                _candidatesMap[candidate.category][candidate.matricNo]
                    .votesAgainst++;
            }
        }
        _votersMap[voterMatricNo].voterState = VoterState.VOTED;
        s_votedVotersCount++;
        emit VoterVoted();
    }

    /**
     * @dev Adds voters to the election after creation. Can only be called by election creator before election starts.
     * @param votersList Array of voters to register
     */
    function addVoters(
        address creatorAddress,
        VoterInfoDTO[] memory votersList
    )
        public
        onlyOwner
        onlyElectionCreator(creatorAddress)
        beforeElectionStarted
    {
        _updateElectionState();
        _registerVoters(votersList);
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
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            if (compareStrings(categoryName, _electionCategories[i])) {
                return true;
            }
        }
        return false;
    }

    // Validate the categories inputed
    function _validateCategories(string[] memory votedCategories) internal {
        for (uint256 i = 0; i < votedCategories.length; i++) {
            string memory category = votedCategories[i];
            if (s_validCategories[category]) {
                revert Election__DuplicateCategory();
            } else {
                _electionCategories.push(category);
                s_validCategories[category] = true;
            }
        }
    }

    /**
     * @dev Updates the election state based on current timestamp
     */
    function _updateElectionState() internal {
        uint256 currentTs = block.timestamp;
        if (
            currentTs >= i_startTimeStamp &&
            currentTs < i_endTimeStamp &&
            _electionState != ElectionState.STARTED
        ) {
            _electionState = ElectionState.STARTED;
        }
        if (currentTs >= i_endTimeStamp) {
            _electionState = ElectionState.ENDED;
        }
    }

    /**
     * @dev Override function to check owner with custom error
     */
    function _checkOwner() internal view override {
        if (owner() != _msgSender()) {
            revert Election__UnauthorizedAccountOnlyVotsEngineCanCallContract(
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
        uint256 vLength = votersList.length;
        if (vLength < 1) {
            revert Election__VoterInfoDTOCannotBeEmpty();
        }
        if (vLength > VOTERS_BATCH_LIMIT) {
            revert Election__VoterInfoListAboveBatchLimit(
                VOTERS_BATCH_LIMIT,
                vLength
            );
        }
        // add all voters to votersList
        for (uint256 i = 0; i < vLength; i++) {
            VoterInfoDTO memory voter = votersList[i];
            // create an electionVoter from voter
            ElectionVoter memory registeredVoter = ElectionVoter({
                name: voter.name,
                level: voter.level,
                department: voter.department,
                voterState: VoterState.REGISTERED
            });
            // add to votersList if the state is unknown
            if (_votersMap[voter.matricNo].voterState == VoterState.UNKNOWN) {
                _votersMap[voter.matricNo] = registeredVoter;
            } else {
                revert Election__DuplicateVoter(voter.matricNo);
            }
            s_registeredVotersList.push(voter.matricNo);
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
        uint256 cLength = candidatesList.length;
        if (_electionCategories.length == 0) {
            revert Election__RegisterCategoriesMustBeCalledBeforeRegisterVoters();
        }

        // add all Candidates to _candidateMap
        for (uint256 i = 0; i < cLength; i++) {
            CandidateInfoDTO memory candidate = candidatesList[i];
            // create an ElectionCandidate from candidate
            ElectionCandidate memory registeredCandidate = ElectionCandidate({
                name: candidate.name,
                votes: 0,
                votesAgainst: 0,
                state: CandidateState.REGISTERED
            });
            // Check that it is a valid election category
            if (!s_validCategories[candidate.category]) {
                revert Election__InvalidCategory(candidate.category);
            }
            if (
                _candidatesMap[candidate.category][candidate.matricNo].state ==
                CandidateState.UNKNOWN
            ) {
                // add to candidateList
                _candidatesMap[candidate.category][
                    candidate.matricNo
                ] = registeredCandidate;
            } else {
                revert Election__DuplicateCandidate(candidate.matricNo);
            }
            s_registeredCandidatesList.push(candidate.matricNo);
        }
    }

    /**
     * @dev Registers polling officers and polling units
     * @param pollingOfficerAddresses Array of polling officer addresses
     * @param pollingUnitAddresses Array of polling unit addresses
     */
    function _registerOfficersAndUnits(
        PollIdentifier[] memory pollingOfficerAddresses,
        PollIdentifier[] memory pollingUnitAddresses
    ) internal onlyOwner {
        if (
            pollingOfficerAddresses.length < 1 ||
            pollingUnitAddresses.length < 1
        ) {
            revert Election__PollingOfficerAndUnitCannotBeEmpty();
        }

        for (uint256 i = 0; i < pollingOfficerAddresses.length; i++) {
            PollIdentifier memory pollingOfficer = pollingOfficerAddresses[i];
            address officerAddress = pollingOfficer.pollAddress;
            if (officerAddress == i_createdBy) {
                revert Election__AddressCanOnlyHaveOneRole();
            }
            if (compareStrings(pollingOfficer.pollRoleName, "")) {
                revert Election__PollingOfficerOrUnitNameEmpty();
            }
            _allowedPollingOfficers[officerAddress] = true;
        }
        for (uint256 i = 0; i < pollingUnitAddresses.length; i++) {
            PollIdentifier memory pollingUnit = pollingUnitAddresses[i];
            address unitAddress = pollingUnit.pollAddress;
            if (
                unitAddress == i_createdBy ||
                _allowedPollingOfficers[unitAddress]
            ) {
                revert Election__AddressCanOnlyHaveOneRole();
            }

            if (compareStrings(pollingUnit.pollRoleName, "")) {
                revert Election__PollingOfficerOrUnitNameEmpty();
            }
            _allowedPollingUnits[unitAddress] = true;
        }

        s_pollingOfficersAddressList = pollingOfficerAddresses;
        s_pollingUnitsAddressList = pollingUnitAddresses;
    }

    function getVotersBatchLimit() external pure returns (uint256) {
        return VOTERS_BATCH_LIMIT;
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

    function getfirstWord(
        string memory fullName
    ) public pure returns (string memory firstWord) {
        strings.slice memory s = fullName.toSlice();
        firstWord = s.split(" ".toSlice()).toString();
    }
}
