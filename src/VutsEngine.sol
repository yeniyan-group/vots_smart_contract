// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
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

    // constructor() {}
    function createElection(
        uint256 startTimeStamp,
        uint256 endTimeStamp,
        string memory electionName,
        Election.CandidateInfoDTO[] memory candidatesList,
        Election.VoterInfoDTO[] memory votersList,
        address[] memory pollingUnitAddresses,
        address[] memory pollingOfficerAddresses
    ) public {
        // Check that electionName is not duplicate
        uint256 tokenId = electionNameToTokenId[electionName];
        if (tokenId > 0) {
            revert VutsEngine__DuplicateElectionName(electionName);
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
            pollingOfficerAddresses: pollingOfficerAddresses
        });
        // Store election address
        electionTokenToAddress[newElectionTokenId] = address(
            newElectionContract
        );
        // Emit creation event
        emit ElectionContractedCreated(newElectionTokenId, electionName);
    }

    function accrediteVoter(
        string memory voterMatricNo,
        uint256 electionTokenId
    ) public validElection(electionTokenId) {
        // Call accredite function
        Election(electionTokenToAddress[electionTokenId]).accrediteVoter(
            voterMatricNo,
            msg.sender
        );
    }

    function voteCandidates(
        string memory voterMatricNo,
        string memory voterName,
        Election.CandidateInfoDTO[] memory candidatesList,
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
}
