// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Election} from "../../src/VutsEngine.sol";

contract ElectionTest is Test {
    address public creator = makeAddr("creator");
    uint256 constant ELECTION_TOKEN_ID = 1;
    string constant ELECTION_NAME = "DUMMY_ELECTION";
    Election public election;

    address public pollingOfficer1 = makeAddr("pollingOfficer1");
    address public pollingOfficer2 = makeAddr("pollingOfficer2");
    address public pollingUnit1 = makeAddr("pollingUnit1");
    address public pollingUnit2 = makeAddr("pollingUnit2");
    address public unknownAddress = makeAddr("unknownAddress");

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    string[] public electionCategories;
    string[] public duplicateCat;

    Election.CandidateInfoDTO candidateOne =
        Election.CandidateInfoDTO({
            name: "Ayeni Samuel",
            matricNo: "CAND001",
            category: "President"
        });
    Election.CandidateInfoDTO candidateTwo =
        Election.CandidateInfoDTO({
            name: "Leumas Ineya",
            matricNo: "CAND002",
            category: "President"
        });
    Election.CandidateInfoDTO candidateThree =
        Election.CandidateInfoDTO({
            name: "Bob Johnson",
            matricNo: "CAND003",
            category: "VicePresident"
        });
    Election.CandidateInfoDTO candidateFour =
        Election.CandidateInfoDTO({
            name: "Nosnhoj Bob",
            matricNo: "CAND004",
            category: "VicePresident"
        });
    Election.CandidateInfoDTO unknownCandidate =
        Election.CandidateInfoDTO({
            name: "Unknown Bob",
            matricNo: "CAND0088",
            category: "UNKNOWNGUY"
        });

    Election.VoterInfoDTO voterOne =
        Election.VoterInfoDTO({name: "Voter1", matricNo: "VOT001"});
    Election.VoterInfoDTO voterTwo =
        Election.VoterInfoDTO({name: "Voter2", matricNo: "VOT002"});
    Election.VoterInfoDTO voterThree =
        Election.VoterInfoDTO({name: "Voter3", matricNo: "VOT003"});
    Election.VoterInfoDTO voterFour =
        Election.VoterInfoDTO({name: "Voter4", matricNo: "VOT004"});
    Election.VoterInfoDTO voterFive =
        Election.VoterInfoDTO({name: "Voter5", matricNo: "VOT005"});
    Election.VoterInfoDTO unknownVoter =
        Election.VoterInfoDTO({name: "This Unknown", matricNo: "VOT007"});

    Election.CandidateInfoDTO[] candidatesList;
    Election.VoterInfoDTO[] votersList;
    address[] pollingOfficerAddresses;
    address[] pollingUnitAddresses;

    function setUp() public {
        // Set timestamps relative to current time
        startTimestamp = block.timestamp + 1 hours;
        endTimestamp = block.timestamp + 2 hours;

        // Setup test candidates
        candidatesList.push(candidateOne);
        candidatesList.push(candidateTwo);
        candidatesList.push(candidateThree);
        candidatesList.push(candidateFour);

        // Setup test voters
        votersList.push(voterOne);
        votersList.push(voterTwo);
        votersList.push(voterThree);
        votersList.push(voterFour);
        votersList.push(voterFive);

        // Setup polling addresses
        pollingOfficerAddresses.push(pollingOfficer1);
        pollingOfficerAddresses.push(pollingOfficer2);

        // Setup polling unit addresses
        pollingUnitAddresses.push(pollingUnit1);
        pollingUnitAddresses.push(pollingUnit2);

        //
        electionCategories = ["President", "VicePresident"];
        duplicateCat = ["President", "VicePresident", "VicePresident"];

        election = new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
    }

    // ====================================================================
    // Constructor Tests
    // ====================================================================
    function testElectionIsCreatedWithRightCredentials() public {
        election = new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        // Verify basic properties
        assertEq(election.getCreatedBy(), creator);
        assertEq(election.getElectionUniqueTokenId(), ELECTION_TOKEN_ID);
        assertEq(election.getStartTimeStamp(), startTimestamp);
        assertEq(election.getEndTimeStamp(), endTimestamp);
        assertEq(election.getElectionName(), ELECTION_NAME);
        assertEq(
            uint256(election.getElectionState()),
            uint256(Election.ElectionState.OPENED)
        );

        // Verify counts
        assertEq(election.getRegisteredVotersCount(), votersList.length);
        assertEq(
            election.getRegisteredCandidatesCount(),
            candidatesList.length
        );
        assertEq(
            election.getPollingOfficerCount(),
            pollingOfficerAddresses.length
        );
        assertEq(election.getPollingUnitCount(), pollingUnitAddresses.length);

        // Initial counts should be zero
        assertEq(election.getAccreditedVotersCount(), 0);
        assertEq(election.getVotedVotersCount(), 0);
    }

    function testElectionRevertWhenInvalidStartTimeStamp() public {
        uint256 pastTimestamp = startTimestamp - 1 hours;

        vm.expectRevert(Election.Election__InvalidStartTimeStamp.selector);
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: pastTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenInvalidEndTimeStamp() public {
        uint256 invalidEndTimestamp = startTimestamp - 1 hours;

        vm.expectRevert(Election.Election__InvalidEndTimeStamp.selector);
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: invalidEndTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenEmptyVotersList() public {
        Election.VoterInfoDTO[] memory emptyVoters;

        vm.expectRevert(Election.Election__VoterInfoDTOCannotBeEmpty.selector);
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: emptyVoters,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenEmptyCandidatesList() public {
        Election.CandidateInfoDTO[] memory emptyCandidates;

        vm.expectRevert(
            Election.Election__CandidatesInfoDTOCannotBeEmpty.selector
        );
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: emptyCandidates,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenEmptyPollingOfficers() public {
        address[] memory emptyOfficers;

        vm.expectRevert(
            Election.Election__PollingOfficerAndUnitCannotBeEmpty.selector
        );
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: emptyOfficers,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenEmptyPollingUnits() public {
        address[] memory emptyPollingUnits;

        vm.expectRevert(
            Election.Election__PollingOfficerAndUnitCannotBeEmpty.selector
        );
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: emptyPollingUnits,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenCreatorHasMultipleRoles() public {
        // Make creator also a polling officer
        address[] memory conflictingOfficers = new address[](1);
        conflictingOfficers[0] = creator;

        vm.expectRevert(Election.Election__AddressCanOnlyHaveOneRole.selector);
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: conflictingOfficers,
            electionCategories: electionCategories
        });
    }

    function testElectionRevertWhenCategoryHasDuplicate() public {
        vm.expectRevert(Election.Election__DuplicateCategory.selector);
        new Election({
            createdBy: creator,
            electionUniqueTokenId: ELECTION_TOKEN_ID,
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: duplicateCat
        });
    }

    // ====================================================================
    // Election State Tests
    // ====================================================================
    function testElectionStateProgressionOverTime() public {
        // Initially OPENED
        assertEq(
            uint256(election.getElectionState()),
            uint256(Election.ElectionState.OPENED)
        );

        // Move to start time
        vm.warp(startTimestamp);
        assertEq(
            uint256(election.getElectionState()),
            uint256(Election.ElectionState.STARTED)
        );

        // Move to end time
        vm.warp(endTimestamp);
        assertEq(
            uint256(election.getElectionState()),
            uint256(Election.ElectionState.ENDED)
        );
    }

    function testUpdateElectionStateFunction() public {
        // Move to start time and update
        vm.warp(startTimestamp);
        election.updateElectionState();
        assertEq(
            uint256(election.getElectionState()),
            uint256(Election.ElectionState.STARTED)
        );

        // Move to end time and update
        vm.warp(endTimestamp);
        election.updateElectionState();
        assertEq(
            uint256(election.getElectionState()),
            uint256(Election.ElectionState.ENDED)
        );
    }

    // ====================================================================
    // Voter Accreditation Tests
    // ====================================================================

    function testAccrediteVoterSuccess() public {
        // Move to election start time
        vm.warp(startTimestamp);

        vm.expectEmit(false, false, false, true, address(election));
        emit Election.AccreditedVoter(voterOne.matricNo);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Verify accredited count increased
        assertEq(election.getAccreditedVotersCount(), 1);
    }

    function testAccrediteVoterRevertWhenElectionNotStarted() public {
        // Try to accredite before election starts
        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.STARTED,
                Election.ElectionState.OPENED
            )
        );
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
    }

    function testAccrediteVoterRevertWhenElectionEnded() public {
        // Move past election end time
        vm.warp(endTimestamp + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.STARTED,
                Election.ElectionState.ENDED
            )
        );

        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
    }

    function testAccrediteVoterRevertWhenUnknownVoter() public {
        vm.warp(startTimestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__UnknownVoter.selector,
                "UNKNOWN_VOTER"
            )
        );
        election.accrediteVoter("UNKNOWN_VOTER", pollingOfficer1);
    }

    function testAccrediteVoterRevertWhenUnauthorizedPollingOfficer() public {
        vm.warp(startTimestamp);

        vm.expectRevert(Election.Election__OnlyPollingOfficerAllowed.selector);

        election.accrediteVoter(voterOne.matricNo, unknownAddress);
    }

    function testAccrediteVoterRevertWhenNotOwner() public {
        vm.warp(startTimestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                Election
                    .Election__UnauthorizedAccountOnlyVutsEngineCanCallContract
                    .selector,
                unknownAddress
            )
        );

        vm.prank(unknownAddress);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
    }

    // ====================================================================
    // Voting Tests
    // ====================================================================

    function testVoteCandidatesSuccess() public {
        vm.warp(startTimestamp);

        // First accredite the voter
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Prepare voting candidates
        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateTwo;

        vm.expectEmit(false, false, false, true);
        emit Election.VoterVoted();

        election.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            pollingUnit1,
            votingCandidates
        );

        // Verify voted count increased
        assertEq(election.getVotedVotersCount(), 1);
    }

    function testVoteCandidatesRevertWhenElectionNotStarted() public {
        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.STARTED,
                Election.ElectionState.OPENED
            )
        );

        election.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            pollingUnit1,
            votingCandidates
        );
    }

    function testVoteCandidatesRevertWhenUnknownVoter() public {
        vm.warp(startTimestamp);

        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__UnknownVoter.selector,
                unknownVoter.matricNo
            )
        );

        election.voteCandidates(
            unknownVoter.matricNo,
            unknownVoter.name,
            pollingUnit1,
            votingCandidates
        );
    }

    function testVoteCandidatesRevertWhenVoterNotAccredited() public {
        vm.warp(startTimestamp);

        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__UnaccreditedVoter.selector,
                voterOne.matricNo
            )
        );

        election.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            pollingUnit1,
            votingCandidates
        );
    }

    function testVoteCandidatesRevertWhenEmptyCandidatesList() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory emptyCandidates;

        vm.expectRevert(
            Election.Election__CandidatesInfoDTOCannotBeEmpty.selector
        );

        election.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            pollingUnit1,
            emptyCandidates
        );
    }

    function testVoteCandidatesRevertWhenVoterNameMismatch() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(Election.Election__VoterCannotBeValidated.selector);

        election.voteCandidates(
            voterOne.matricNo,
            "WRONGNAMEEEE",
            pollingUnit1,
            votingCandidates
        );
    }

    function testVoteCandidatesRevertWhenUnauthorizedPollingUnit() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(Election.Election__OnlyPollingUnitAllowed.selector);

        election.voteCandidates(
            voterOne.matricNo,
            "Alice Johnson",
            unknownAddress,
            votingCandidates
        );
    }

    function testVoteCandidatesRevertWhenNotOwner() public {
        vm.warp(startTimestamp);

        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election
                    .Election__UnauthorizedAccountOnlyVutsEngineCanCallContract
                    .selector,
                unknownAddress
            )
        );

        vm.prank(unknownAddress);
        election.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            pollingUnit1,
            votingCandidates
        );
    }

    function testVoteCandidatesRevertWhenInvalidCategoryVoted() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[]
            memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = unknownCandidate;

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidCategory.selector,
                unknownCandidate.category
            )
        );

        election.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            pollingUnit1,
            votingCandidates
        );
    }

    // ====================================================================
    // Utility Function Tests
    // ====================================================================

    function testCompareStringsSuccess() public view {
        assertTrue(election.compareStrings("hello", "hello"));
        assertFalse(election.compareStrings("hello", "world"));
        assertTrue(election.compareStrings("", ""));
        assertFalse(election.compareStrings("test", ""));
    }
}
