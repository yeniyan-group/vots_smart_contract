// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IElection} from "../interfaces/IElection.sol";
import {IVotsEngine} from "../interfaces/IVotsEngine.sol";

/**
 * @title VotsEngineLib
 * @notice Library containing helper functions for VotsEngine
 */
library VotsEngineLib {
    // Custom errors
    error VotsEngine__ElectionNotFound();

    /**
     * @dev Validates election exists and returns the election contract instance
     * @param tokenToAddress Mapping from token ID to election address
     * @param electionTokenId The token ID of the election
     * @return election The IElection contract instance
     */
    function validateAndGetElection(mapping(uint256 => address) storage tokenToAddress, uint256 electionTokenId)
        internal
        view
        returns (IElection election)
    {
        address electionAddr = tokenToAddress[electionTokenId];
        if (electionAddr == address(0)) revert VotsEngine__ElectionNotFound();
        return IElection(electionAddr);
    }

    /**
     * @dev Gets election stats from the election contract
     * @param tokenToAddress Mapping from token ID to election address
     * @param electionTokenId The token ID of the election
     */
    function getElectionStats(mapping(uint256 => address) storage tokenToAddress, uint256 electionTokenId)
        internal
        view
        returns (
            uint256 registeredVotersCount,
            uint256 accreditedVotersCount,
            uint256 votedVotersCount,
            uint256 registeredCandidatesCount,
            uint256 pollingOfficerCount,
            uint256 pollingUnitCount
        )
    {
        IElection election = validateAndGetElection(tokenToAddress, electionTokenId);
        return (
            election.getRegisteredVotersCount(),
            election.getAccreditedVotersCount(),
            election.getVotedVotersCount(),
            election.getRegisteredCandidatesCount(),
            election.getPollingOfficerCount(),
            election.getPollingUnitCount()
        );
    }

    /**
     * @dev Creates election summary from election contract data
     * @param election The election contract instance
     * @return summary The election summary struct
     */
    function createElectionSummary(IElection election)
        internal
        view
        returns (IVotsEngine.ElectionSummary memory summary)
    {
        return IVotsEngine.ElectionSummary({
            electionId: election.getElectionUniqueTokenId(),
            electionName: election.getElectionName(),
            electionDescription: election.getElectionDescription(),
            state: election.getElectionState(),
            startTimestamp: election.getStartTimeStamp(),
            endTimestamp: election.getEndTimeStamp(),
            registeredVotersCount: election.getRegisteredVotersCount()
        });
    }

    /**
     * @dev Creates detailed election info from election contract data
     * @param election The election contract instance
     * @return info The detailed election information struct
     */
    function createElectionInfo(IElection election) internal view returns (IVotsEngine.ElectionInfo memory info) {
        return IVotsEngine.ElectionInfo({
            electionId: election.getElectionUniqueTokenId(),
            createdBy: election.getCreatedBy(),
            electionName: election.getElectionName(),
            electionDescription: election.getElectionDescription(),
            state: election.getElectionState(),
            startTimestamp: election.getStartTimeStamp(),
            endTimestamp: election.getEndTimeStamp(),
            registeredVotersCount: election.getRegisteredVotersCount(),
            accreditedVotersCount: election.getAccreditedVotersCount(),
            votedVotersCount: election.getVotedVotersCount(),
            electionCategories: election.getElectionCategories(),
            candidatesList: election.getAllCandidatesInDto(),
            pollingOfficers: election.getPollingOfficersAddresses(),
            pollingUnits: election.getPollingUnitsAddresses()
        });
    }

    /**
     * @dev Validates voter for voting through election contract
     * @param tokenToAddress Mapping from token ID to election address
     * @param voterMatricNo Voter's matriculation number
     * @param voterName Voter's name
     * @param electionTokenId The token ID of the election
     * @param sender The message sender address
     * @return isValid Whether the voter is valid for voting
     */
    function validateVoterForVoting(
        mapping(uint256 => address) storage tokenToAddress,
        string memory voterMatricNo,
        string memory voterName,
        uint256 electionTokenId,
        address sender
    ) internal returns (bool isValid) {
        IElection election = validateAndGetElection(tokenToAddress, electionTokenId);
        return election.validateVoterForVoting(voterName, voterMatricNo, sender);
    }

    /**
     * @dev Validates address as polling unit through election contract
     * @param tokenToAddress Mapping from token ID to election address
     * @param electionTokenId The token ID of the election
     * @param sender The message sender address
     * @return isValid Whether the address is a valid polling unit
     */
    function validateAddressAsPollingUnit(
        mapping(uint256 => address) storage tokenToAddress,
        uint256 electionTokenId,
        address sender
    ) internal returns (bool isValid) {
        IElection election = validateAndGetElection(tokenToAddress, electionTokenId);
        return election.validateAddressAsPollingUnit(sender);
    }

    /**
     * @dev Validates address as polling officer through election contract
     * @param tokenToAddress Mapping from token ID to election address
     * @param electionTokenId The token ID of the election
     * @param sender The message sender address
     * @return isValid Whether the address is a valid polling officer
     */
    function validateAddressAsPollingOfficer(
        mapping(uint256 => address) storage tokenToAddress,
        uint256 electionTokenId,
        address sender
    ) internal returns (bool isValid) {
        IElection election = validateAndGetElection(tokenToAddress, electionTokenId);
        return election.validateAddressAsPollingOfficer(sender);
    }
}
