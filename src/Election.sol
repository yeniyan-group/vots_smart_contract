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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VutsEngine
 * @author Ayeni-yeniyan
 * @notice This election contract stores the election information for an election in the VutsEngine.
 * Each election is owned by the VutsEngine. It holds a createdBy field which keeps the information of the election creator
 *
 */
contract Election is Ownable {
    /// @dev Creator of the election
    address immutable createdBy;

    /// @dev The unique token identifier for this election
    uint256 immutable electionUniqueTokenId;

    /// @dev The unique election name for this election
    string electionName;

    /// @dev mapping of matric number(Unique identifier) to voter
    mapping(string matricNo => ElectionVoter voter) private _votersList;

    /// @dev map of category to candidatenames to candidate
    mapping(string categoryName => mapping(string candidateName => ElectionCandidates electionCandidates))
        private _canddatesList;

    /// @dev Election state
    ElectionState private _electionState;

    /// @dev Defines the structure of our voter

    struct ElectionVoter {
        string name;
        VoterState voterState;
    }
    struct ElectionCandidates {
        string name;
        uint256 votes;
    }
    /// @dev Winner of each election category
    struct ElectionWinner {
        ElectionCandidates electionCandidates;
        string category;
    }
    // Enums

    // Election State
    enum ElectionState {
        OPENED,
        STARTED,
        ENDED
    }

    // Voters state
    enum VoterState {
        REGISTERED,
        ACCREDITED,
        VOTED
    }

    constructor(
        address _createdBy,
        uint256 _electionUniqueTokenId,
        string memory _electionName
    ) Ownable(msg.sender) {
        createdBy = _createdBy;
        electionUniqueTokenId = _electionUniqueTokenId;
        electionName = _electionName;
    }
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
