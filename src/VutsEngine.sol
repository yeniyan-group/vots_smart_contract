// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {Election} from "./Election.sol";

/**
 * @title VutsEngine
 * @author Ayeni-yeniyan
 * @notice This is the core of the voting system.
 * This contract creates the election contract and tokenises the created contract address.
 * Only this contract has access to interact with the election contracts.
 * When an election is created, it gets a unique election id which identifies it.
 * An election contract is created with a unique name that is stored in memory and can be used to get the election address.
 * Each election is tokenised and the address is stored on chain to enable future access and reference.
 */
contract VutsEngine {
    // ====================================================================
    // Errors
    // ====================================================================
    error VutsEngine__DuplicateElectionName(string electionName);
    error VutsEngine__ElectionContractNotFound(uint256 electionTokenId);
    error VutsEngine__ElectionNameCannotBeEmpty();

    // ====================================================================
    // Events
    // ====================================================================
    event ElectionContractedCreated(
        uint256 newElectionTokenId,
        string electionName
    );

    uint256 tokenIdCount;
    mapping(uint256 tokenId => address electionAddress) electionTokenToAddress;
    mapping(string electionName => uint256 tokenId) electionNameToTokenId;

    modifier validElection(uint256 electionTokenId) {
        if (electionTokenToAddress[electionTokenId] == address(0)) {
            revert VutsEngine__ElectionContractNotFound(electionTokenId);
        }
        _;
    }

    struct ElectionSummary {
        uint256 electionId;
        string electionName;
        Election.ElectionState state;
    }

    function createElection(
        uint256 startTimeStamp,
        uint256 endTimeStamp,
        string calldata electionName,
        Election.CandidateInfoDTO[] calldata candidatesList,
        Election.VoterInfoDTO[] calldata votersList,
        address[] calldata pollingUnitAddresses,
        address[] calldata pollingOfficerAddresses,
        string[] calldata electionCategories
    ) public {
        // Check that electionName is not duplicate
        uint256 tokenId = electionNameToTokenId[electionName];
        if (tokenId > 0) {
            revert VutsEngine__DuplicateElectionName(electionName);
        }
        if (bytes(electionName).length == 0) {
            revert VutsEngine__ElectionNameCannotBeEmpty();
        }
        // Generate tokenId for election
        uint256 newElectionTokenId = ++tokenIdCount;

        Election newElectionContract = new Election({
            createdBy: msg.sender,
            electionUniqueTokenId: newElectionTokenId,
            startTimeStamp: startTimeStamp,
            endTimeStamp: endTimeStamp,
            electionName: electionName,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        // Store election address
        electionTokenToAddress[newElectionTokenId] = address(
            newElectionContract
        );
        // Store election name
        electionNameToTokenId[electionName] = newElectionTokenId;
        // Emit creation event
        emit ElectionContractedCreated(newElectionTokenId, electionName);
    }

    function accrediteVoter(
        string calldata voterMatricNo,
        uint256 electionTokenId
    ) public validElection(electionTokenId) {
        // Call accredite function
        Election(electionTokenToAddress[electionTokenId]).accrediteVoter(
            voterMatricNo,
            msg.sender
        );
    }

    function voteCandidates(
        string calldata voterMatricNo,
        string calldata voterName,
        Election.CandidateInfoDTO[] calldata candidatesList,
        uint256 electionTokenId
    ) public validElection(electionTokenId) {
        // Call vote function
        Election(electionTokenToAddress[electionTokenId]).voteCandidates(
            voterMatricNo,
            voterName,
            msg.sender,
            candidatesList
        );
    }

    function validateVoterForVoting(
        string memory voterMatricNo,
        string memory voterName,
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (bool) {
        return
            Election(electionTokenToAddress[electionTokenId])
                .validateVoterForVoting(voterName, voterMatricNo, msg.sender);
    }

    function validateAddressAsPollingUnit(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (bool) {
        return
            Election(electionTokenToAddress[electionTokenId])
                .validateAddressAsPollingUnit(msg.sender);
    }

    function validateAddressAsPollingOfficer(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (bool) {
        return
            Election(electionTokenToAddress[electionTokenId])
                .validateAddressAsPollingOfficer(msg.sender);
    }

    // ====================================================================
    // Getter Functions - Engine Level
    // ====================================================================

    /**
     * @dev Returns the total number of elections created
     * @return uint256 Total election count
     */
    function getTotalElectionsCount() public view returns (uint256) {
        return tokenIdCount;
    }

    /**
     * @dev Returns the election contract address for a given token ID
     * @param electionTokenId The token ID of the election
     * @return address Election contract address
     */
    function getElectionAddress(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (address) {
        return electionTokenToAddress[electionTokenId];
    }

    /**
     * @dev Returns the token ID for a given election name
     * @param electionName The name of the election
     * @return uint256 Token ID (returns 0 if not found)
     */
    function getElectionTokenId(
        string calldata electionName
    ) public view returns (uint256) {
        return electionNameToTokenId[electionName];
    }

    /**
     * @dev Checks if an election exists by name
     * @param electionName The name of the election
     * @return bool True if election exists
     */
    function electionExists(
        string calldata electionName
    ) public view returns (bool) {
        return electionNameToTokenId[electionName] > 0;
    }

    /**
     * @dev Checks if an election exists by token ID
     * @param electionTokenId The token ID of the election
     * @return bool True if election exists
     */
    function electionExistsByTokenId(
        uint256 electionTokenId
    ) public view returns (bool) {
        return electionTokenToAddress[electionTokenId] != address(0);
    }

    // ====================================================================
    // Getter Functions - Election Data Forwarding
    // ====================================================================

    /**
     * @dev Returns basic election information
     * @param electionTokenId The token ID of the election
     */
    function getElectionInfo(
        uint256 electionTokenId
    )
        public
        view
        validElection(electionTokenId)
        returns (
            address createdBy,
            string memory electionName,
            uint256 startTimeStamp,
            uint256 endTimeStamp,
            Election.ElectionState electionState
        )
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return (
            election.getCreatedBy(),
            election.getElectionName(),
            election.getStartTimeStamp(),
            election.getEndTimeStamp(),
            election.getElectionState()
        );
    }

    /**
     * @dev Returns the count of registered voters for an election
     * @param electionTokenId The token ID of the election
     */
    function getRegisteredVotersCount(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (uint256) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getRegisteredVotersCount();
    }

    /**
     * @dev Returns the count of accredited voters for an election
     * @param electionTokenId The token ID of the election
     */
    function getAccreditedVotersCount(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (uint256) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getAccreditedVotersCount();
    }

    /**
     * @dev Returns the count of voters who have voted for an election
     * @param electionTokenId The token ID of the election
     */
    function getVotedVotersCount(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (uint256) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getVotedVotersCount();
    }

    /**
     * @dev Returns the count of registered candidates for an election
     * @param electionTokenId The token ID of the election
     */
    function getRegisteredCandidatesCount(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (uint256) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getRegisteredCandidatesCount();
    }

    /**
     * @dev Returns the count of polling officers for an election
     * @param electionTokenId The token ID of the election
     */
    function getPollingOfficerCount(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (uint256) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getPollingOfficerCount();
    }

    /**
     * @dev Returns the count of polling units for an election
     * @param electionTokenId The token ID of the election
     */
    function getPollingUnitCount(
        uint256 electionTokenId
    ) public view validElection(electionTokenId) returns (uint256) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getPollingUnitCount();
    }

    /**
     * @dev Returns election statistics (original combined function)
     * @param electionTokenId The token ID of the election
     */
    function getElectionStats(
        uint256 electionTokenId
    )
        public
        view
        validElection(electionTokenId)
        returns (
            uint256 registeredVotersCount,
            uint256 accreditedVotersCount,
            uint256 votedVotersCount,
            uint256 registeredCandidatesCount,
            uint256 pollingOfficerCount,
            uint256 pollingUnitCount
        )
    {
        return (
            getRegisteredVotersCount(electionTokenId),
            getAccreditedVotersCount(electionTokenId),
            getVotedVotersCount(electionTokenId),
            getRegisteredCandidatesCount(electionTokenId),
            getPollingOfficerCount(electionTokenId),
            getPollingUnitCount(electionTokenId)
        );
    }

    /**
     * @dev Returns all voters for an election
     * @param electionTokenId The token ID of the election
     */
    function getAllVoters(
        uint256 electionTokenId
    )
        public
        view
        validElection(electionTokenId)
        returns (Election.ElectionVoter[] memory)
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getAllVoters();
    }

    /**
     * @dev Returns all accredited voters for an election
     * @param electionTokenId The token ID of the election
     */
    function getAllAccreditedVoters(
        uint256 electionTokenId
    )
        public
        view
        validElection(electionTokenId)
        returns (Election.ElectionVoter[] memory)
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getAllAccreditedVoters();
    }

    /**
     * @dev Returns all voters who have voted for an election
     * @param electionTokenId The token ID of the election
     */
    function getAllVotedVoters(
        uint256 electionTokenId
    )
        public
        view
        validElection(electionTokenId)
        returns (Election.ElectionVoter[] memory)
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getAllVotedVoters();
    }

    /**
     * @dev Returns all candidates for an election (as DTOs)
     * @param electionTokenId The token ID of the election
     */
    function getAllCandidatesInDto(
        uint256 electionTokenId
    )
        public
        view
        validElection(electionTokenId)
        returns (Election.CandidateInfoDTO[] memory)
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getAllCandidatesInDto();
    }

    /**
     * @dev Returns all candidates with vote counts (only after election ends)
     * @param electionTokenId The token ID of the election
     */
    function getAllCandidates(
        uint256 electionTokenId
    )
        public
        validElection(electionTokenId)
        returns (Election.ElectionCandidate[] memory)
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getAllCandidates();
    }

    /**
     * @dev Returns winners for each category (handles ties)
     * @param electionTokenId The token ID of the election
     */
    function getEachCategoryWinner(
        uint256 electionTokenId
    )
        public
        validElection(electionTokenId)
        returns (Election.ElectionWinner[][] memory)
    {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        return election.getEachCategoryWinner();
    }

    // ====================================================================
    // Utility Functions
    // ====================================================================

    /**
     * @dev Updates election state for a specific election
     * @param electionTokenId The token ID of the election
     */
    function updateElectionState(
        uint256 electionTokenId
    ) public validElection(electionTokenId) {
        Election election = Election(electionTokenToAddress[electionTokenId]);
        election.updateElectionState();
    }

    /**
     * @dev Returns a summary of all elections (basic info only)
     * @return electionsSummaryList Array of the election summary
     */
    function getAllElectionsSummary()
        public
        view
        returns (ElectionSummary[] memory electionsSummaryList)
    {
        uint256 totalElections = tokenIdCount;
        electionsSummaryList = new ElectionSummary[](totalElections);

        for (uint256 i = 1; i <= totalElections; i++) {
            if (electionTokenToAddress[i] != address(0)) {
                Election election = Election(electionTokenToAddress[i]);
                electionsSummaryList[i - 1] = ElectionSummary({
                    electionId: election.getElectionUniqueTokenId(),
                    electionName: election.getElectionName(),
                    state: election.getElectionState()
                });
            }
        }
    }
}
