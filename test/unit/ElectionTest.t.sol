// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Election} from "../../src/Election.sol";

contract ElectionTest is Test {
    address public creator = makeAddr("creator");
    uint256 constant ELECTION_TOKEN_ID = 1;
    string constant ELECTION_NAME = "DUMMY_ELECTION";
    string constant ELECTION_DESCRIPTION = "DUMMY_ELECTION_DESCRIPTION";
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

    Election.CandidateInfoDTO candidateOne = Election.CandidateInfoDTO({
        name: "Ayeni Samuel",
        matricNo: "CAND001",
        category: "President",
        voteFor: 1,
        voteAgainst: 0
    });
    Election.CandidateInfoDTO candidateTwo = Election.CandidateInfoDTO({
        name: "Leumas Ineya",
        matricNo: "CAND002",
        category: "President",
        voteFor: 1,
        voteAgainst: 0
    });
    Election.CandidateInfoDTO candidateThree = Election.CandidateInfoDTO({
        name: "Bob Johnson",
        matricNo: "CAND003",
        category: "Vice President",
        voteFor: 1,
        voteAgainst: 0
    });
    Election.CandidateInfoDTO candidateFour = Election.CandidateInfoDTO({
        name: "Nosnhoj Bob",
        matricNo: "CAND004",
        category: "Vice President",
        voteFor: 1,
        voteAgainst: 0
    });
    Election.CandidateInfoDTO unknownCandidate = Election.CandidateInfoDTO({
        name: "Unknown Bob",
        matricNo: "CAND0088",
        category: "UNKNOWNGUY",
        voteFor: 1,
        voteAgainst: 0
    });

    Election.VoterInfoDTO voterOne = Election.VoterInfoDTO({name: "Voter1", matricNo: "VOT001"});
    Election.VoterInfoDTO voterTwo = Election.VoterInfoDTO({name: "Voter2", matricNo: "VOT002"});
    Election.VoterInfoDTO voterThree = Election.VoterInfoDTO({name: "Voter3", matricNo: "VOT003"});
    Election.VoterInfoDTO voterFour = Election.VoterInfoDTO({name: "Voter4", matricNo: "VOT004"});
    Election.VoterInfoDTO voterFive = Election.VoterInfoDTO({name: "Voter5", matricNo: "VOT005"});
    Election.VoterInfoDTO unknownVoter = Election.VoterInfoDTO({name: "This Unknown", matricNo: "VOT007"});

    Election.CandidateInfoDTO[] candidatesList;
    Election.VoterInfoDTO[] votersList;
    address[] pollingOfficerAddresses;
    address[] pollingUnitAddresses;

    function setUp() public {
        _setupTestData();
        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function _setupTestData() internal {
        // Set timestamps relative to current time
        startTimestamp = block.timestamp + 1 hours;
        endTimestamp = startTimestamp + 7 hours;

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
        electionCategories = ["President", "Vice President"];
        duplicateCat = ["President", "Vice President", "Vice President"];
    }

    // ====================================================================
    // Constructor Tests
    // ====================================================================
    function testElectionIsCreatedWithRightCredentials() public {
        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
        // Verify basic properties
        assertEq(election.getCreatedBy(), creator);
        assertEq(election.getElectionUniqueTokenId(), ELECTION_TOKEN_ID);
        assertEq(election.getStartTimeStamp(), startTimestamp);
        assertEq(election.getEndTimeStamp(), endTimestamp);
        assertEq(election.getElectionName(), ELECTION_NAME);
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.OPENED));

        // Verify counts
        assertEq(election.getRegisteredVotersCount(), votersList.length);
        assertEq(election.getRegisteredCandidatesCount(), candidatesList.length);
        assertEq(election.getPollingOfficerCount(), pollingOfficerAddresses.length);
        assertEq(election.getPollingUnitCount(), pollingUnitAddresses.length);

        // Initial counts should be zero
        assertEq(election.getAccreditedVotersCount(), 0);
        assertEq(election.getVotedVotersCount(), 0);
    }

    function testElectionRevertWhenInvalidStartTimeStamp() public {
        uint256 pastTimestamp = startTimestamp - 1 hours;

        vm.expectRevert(Election.Election__InvalidStartTimeStamp.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: pastTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenInvalidEndTimeStamp() public {
        uint256 invalidEndTimestamp = startTimestamp - 1 hours;

        vm.expectRevert(Election.Election__InvalidEndTimeStamp.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: invalidEndTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenEmptyVotersList() public {
        Election.VoterInfoDTO[] memory emptyVoters;

        vm.expectRevert(Election.Election__VoterInfoDTOCannotBeEmpty.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: emptyVoters,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenEmptyCandidatesList() public {
        Election.CandidateInfoDTO[] memory emptyCandidates;

        vm.expectRevert(Election.Election__CandidatesInfoDTOCannotBeEmpty.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: emptyCandidates,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenEmptyPollingOfficers() public {
        address[] memory emptyOfficers;

        vm.expectRevert(Election.Election__PollingOfficerAndUnitCannotBeEmpty.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: emptyOfficers,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenEmptyPollingUnits() public {
        address[] memory emptyPollingUnits;

        vm.expectRevert(Election.Election__PollingOfficerAndUnitCannotBeEmpty.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: emptyPollingUnits,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenCreatorHasMultipleRoles() public {
        // Make creator also a polling officer
        address[] memory conflictingOfficers = new address[](1);
        conflictingOfficers[0] = creator;

        vm.expectRevert(Election.Election__AddressCanOnlyHaveOneRole.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: conflictingOfficers,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenCategoryHasDuplicate() public {
        vm.expectRevert(Election.Election__DuplicateCategory.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: duplicateCat
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenDuplicateVoter() public {
        Election.VoterInfoDTO[] memory duplicateVoters = new Election.VoterInfoDTO[](2);
        duplicateVoters[0] = voterOne;
        duplicateVoters[1] = voterOne;

        vm.expectRevert(abi.encodeWithSelector(Election.Election__DuplicateVoter.selector, voterOne.matricNo));
        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: duplicateVoters,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenDuplicateCandidate() public {
        Election.CandidateInfoDTO[] memory duplicateCandidates = new Election.CandidateInfoDTO[](2);
        duplicateCandidates[0] = candidateOne;
        duplicateCandidates[1] = candidateOne;

        vm.expectRevert(abi.encodeWithSelector(Election.Election__DuplicateCandidate.selector, candidateOne.matricNo));
        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: duplicateCandidates,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenPollingOfficerIsAlsoPollingUnit() public {
        address[] memory conflictingUnits = new address[](1);
        conflictingUnits[0] = pollingOfficer1; // Same as polling officer

        vm.expectRevert(Election.Election__AddressCanOnlyHaveOneRole.selector);

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: conflictingUnits,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenCandidateCategoryInvalid() public {
        candidatesList.push(unknownCandidate);
        vm.expectRevert(abi.encodeWithSelector(Election.Election__InvalidCategory.selector, "UNKNOWNGUY"));

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    // ====================================================================
    // Election State Tests
    // ====================================================================
    function testElectionStateProgressionOverTime() public {
        // Initially OPENED
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.OPENED));

        // Move to start time
        vm.warp(startTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.STARTED));

        // Move to end time
        vm.warp(endTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.ENDED));
    }

    function testUpdateElectionStateFunction() public {
        // Move to start time and update
        vm.warp(startTimestamp);
        election.updateElectionState();
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.STARTED));

        // Move to end time and update
        vm.warp(endTimestamp);
        election.updateElectionState();
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.ENDED));
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

        vm.expectRevert(abi.encodeWithSelector(Election.Election__UnknownVoter.selector, "UNKNOWN_VOTER"));
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
                Election.Election__UnauthorizedAccountOnlyVotsEngineCanCallContract.selector, unknownAddress
            )
        );

        vm.prank(unknownAddress);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
    }

    function testAccrediteVoterRevertWhenAlreadyAccredited() public {
        vm.warp(startTimestamp);

        // First accreditation
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Try to accredite again
        vm.expectRevert(Election.Election__VoterAlreadyAccredited.selector);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
    }

    function testAccrediteMultipleVotersSuccess() public {
        vm.warp(startTimestamp);

        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);

        assertEq(election.getAccreditedVotersCount(), 2);
    }

    // ====================================================================
    // Voting Tests
    // ====================================================================

    function testVoteCandidatesSuccess() public {
        vm.warp(startTimestamp);

        // First accredite the voter
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Prepare voting candidates
        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateTwo;

        vm.expectEmit(false, false, false, true);
        emit Election.VoterVoted();

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);

        // Verify voted count increased
        assertEq(election.getVotedVotersCount(), 1);
    }

    function testVoteCandidatesRevertWhenElectionNotStarted() public {
        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.STARTED,
                Election.ElectionState.OPENED
            )
        );

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenUnknownVoter() public {
        vm.warp(startTimestamp);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(abi.encodeWithSelector(Election.Election__UnknownVoter.selector, unknownVoter.matricNo));

        election.voteCandidates(unknownVoter.matricNo, unknownVoter.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenVoterNotAccredited() public {
        vm.warp(startTimestamp);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(abi.encodeWithSelector(Election.Election__UnaccreditedVoter.selector, voterOne.matricNo));

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenEmptyCandidatesList() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory emptyCandidates;

        vm.expectRevert(Election.Election__CandidatesInfoDTOCannotBeEmpty.selector);

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, emptyCandidates);
    }

    function testVoteCandidatesRevertWhenVoterNameMismatch() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(Election.Election__VoterCannotBeValidated.selector);

        election.voteCandidates(voterOne.matricNo, "WRONGNAMEEEE", pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenUnauthorizedPollingUnit() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(Election.Election__OnlyPollingUnitAllowed.selector);

        election.voteCandidates(voterOne.matricNo, "Alice Johnson", unknownAddress, votingCandidates);
    }

    function testVoteCandidatesRevertWhenNotOwner() public {
        vm.warp(startTimestamp);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__UnauthorizedAccountOnlyVotsEngineCanCallContract.selector, unknownAddress
            )
        );

        vm.prank(unknownAddress);
        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenInvalidCategoryVoted() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = unknownCandidate;

        vm.expectRevert(abi.encodeWithSelector(Election.Election__InvalidCategory.selector, unknownCandidate.category));

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenVoterAlreadyVoted() public {
        vm.warp(startTimestamp);

        // Accredite and vote first time
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateThree;

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);

        // Try to vote again
        vm.expectRevert(abi.encodeWithSelector(Election.Election__VoterAlreadyVoted.selector));
        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit2, votingCandidates);
    }

    function testVoteCandidatesRevertWhenIncorrectCategoryCount() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Only vote for 1 category when 2 are required
        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](1);
        votingCandidates[0] = candidateOne;

        vm.expectRevert(Election.Election__AllCategoriesMustHaveOnlyOneVotedCandidate.selector);
        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesMultipleVotersSuccess() public {
        vm.warp(startTimestamp);

        // Accredite multiple voters
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateThree;

        // Vote with both voters
        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
        election.voteCandidates(voterTwo.matricNo, voterTwo.name, pollingUnit2, votingCandidates);

        assertEq(election.getVotedVotersCount(), 2);
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

    // ====================================================================
    // Getter Functions
    // ====================================================================

    function testGetAllVotersReturnsCorrectData() public view {
        Election.ElectionVoter[] memory allVoters = election.getAllVoters();
        assertEq(allVoters.length, votersList.length);

        // Check first voter data
        assertEq(allVoters[0].name, voterOne.name);
        assertEq(uint256(allVoters[0].voterState), uint256(Election.VoterState.REGISTERED));
    }

    function testGetAllAccreditedVotersInitiallyEmpty() public view {
        Election.ElectionVoter[] memory accreditedVoters = election.getAllAccreditedVoters();
        assertEq(accreditedVoters.length, 0);
    }

    function testGetAllAccreditedVotersAfterAccreditation() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.ElectionVoter[] memory accreditedVoters = election.getAllAccreditedVoters();
        assertEq(accreditedVoters.length, 1);
        assertEq(accreditedVoters[0].name, voterOne.name);
        assertEq(uint256(accreditedVoters[0].voterState), uint256(Election.VoterState.ACCREDITED));
    }

    function testGetAllVotedVotersInitiallyEmpty() public view {
        Election.ElectionVoter[] memory votedVoters = election.getAllVotedVoters();
        assertEq(votedVoters.length, 0);
    }

    function testGetAllVotedVotersAfterVoting() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        Election.CandidateInfoDTO[] memory votingCandidates = new Election.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateThree;

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);

        Election.ElectionVoter[] memory votedVoters = election.getAllVotedVoters();
        assertEq(votedVoters.length, 1);
        assertEq(votedVoters[0].name, voterOne.name);
        assertEq(uint256(votedVoters[0].voterState), uint256(Election.VoterState.VOTED));
    }

    function testGetAllCandidatesInDto() public view {
        Election.CandidateInfoDTO[] memory candidates = election.getAllCandidatesInDto();
        assertEq(candidates.length, candidatesList.length);

        // Verify first candidate
        assertEq(candidates[0].name, candidateOne.name);
        assertEq(candidates[0].matricNo, candidateOne.matricNo);
        assertEq(candidates[0].category, candidateOne.category);
    }

    // ====================================================================
    // Election Results (Post-Election)
    // ====================================================================

    function testGetAllCandidatesRevertWhenElectionNotEnded() public {
        vm.warp(startTimestamp); // Election started but not ended

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.ENDED,
                Election.ElectionState.STARTED
            )
        );
        election.getAllCandidates();
    }

    function testGetAllCandidatesAfterElectionEnds() public {
        vm.warp(endTimestamp + 1); // Election ended

        Election.ElectionCandidate[] memory candidates = election.getAllCandidates();
        assertEq(candidates.length, candidatesList.length);
    }

    function testGetEachCategoryWinnerRevertWhenElectionNotEnded() public {
        vm.warp(startTimestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.ENDED,
                Election.ElectionState.STARTED
            )
        );
        election.getEachCategoryWinner();
    }

    function testGetEachCategoryWinnerWithNoVotes() public {
        vm.warp(endTimestamp + 1);

        Election.ElectionWinner[][] memory winners = election.getEachCategoryWinner();
        assertEq(winners.length, 2); // Two categories
        assertEq(winners[0].length, 0); // No votes for President
        assertEq(winners[1].length, 0); // No votes for VicePresident
    }

    function testGetEachCategoryWinnerWithVotes() public {
        vm.warp(startTimestamp);

        // Accredite and vote
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);

        Election.CandidateInfoDTO[] memory vote1 = new Election.CandidateInfoDTO[](2);
        vote1[0] = candidateOne; // President
        vote1[1] = candidateThree; // VicePresident

        Election.CandidateInfoDTO[] memory vote2 = new Election.CandidateInfoDTO[](2);
        vote2[0] = candidateOne; // President (same)
        vote2[1] = candidateFour; // VicePresident (different)

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, vote1);
        election.voteCandidates(voterTwo.matricNo, voterTwo.name, pollingUnit2, vote2);

        vm.warp(endTimestamp + 1);

        Election.ElectionWinner[][] memory winners = election.getEachCategoryWinner();
        assertEq(winners.length, 2);
        assertEq(winners[0].length, 1); // One President winner (candidateOne with 2 votes)
        assertEq(winners[1].length, 2); // Two VicePresident winners (tie with 1 vote each)
    }

    function testGetEachCategoryWinnerWithTie() public {
        vm.warp(startTimestamp);

        // Create a tie scenario
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);

        Election.CandidateInfoDTO[] memory vote1 = new Election.CandidateInfoDTO[](2);
        vote1[0] = candidateOne;
        vote1[1] = candidateThree;

        Election.CandidateInfoDTO[] memory vote2 = new Election.CandidateInfoDTO[](2);
        vote2[0] = candidateTwo; // Different president candidate
        vote2[1] = candidateFour; // Different VP candidate

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, vote1);
        election.voteCandidates(voterTwo.matricNo, voterTwo.name, pollingUnit2, vote2);

        vm.warp(endTimestamp + 1);

        Election.ElectionWinner[][] memory winners = election.getEachCategoryWinner();
        assertEq(winners[0].length, 2); // Tie for President
        assertEq(winners[1].length, 2); // Tie for VicePresident
    }

    // ====================================================================
    // Edge Cases and Error Conditions
    // ====================================================================

    function testElectionStateTransitionAtExactTimestamps() public {
        // Test at exact start timestamp
        vm.warp(startTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.STARTED));

        // Test one second before end
        vm.warp(endTimestamp - 1);
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.STARTED));

        // Test at exact end timestamp
        vm.warp(endTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(Election.ElectionState.ENDED));
    }

    function testVoteCountingAccuracy() public {
        vm.warp(startTimestamp);

        // Accredite 3 voters
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);
        election.accrediteVoter(voterThree.matricNo, pollingOfficer1);

        // All vote for candidateOne for President, different for VP
        Election.CandidateInfoDTO[] memory vote1 = new Election.CandidateInfoDTO[](2);
        vote1[0] = candidateOne;
        vote1[1] = candidateThree;

        Election.CandidateInfoDTO[] memory vote2 = new Election.CandidateInfoDTO[](2);
        vote2[0] = candidateOne;
        vote2[1] = candidateThree;

        Election.CandidateInfoDTO[] memory vote3 = new Election.CandidateInfoDTO[](2);
        vote3[0] = candidateOne;
        vote3[1] = candidateFour;

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, vote1);
        election.voteCandidates(voterTwo.matricNo, voterTwo.name, pollingUnit2, vote2);
        election.voteCandidates(voterThree.matricNo, voterThree.name, pollingUnit1, vote3);

        vm.warp(endTimestamp + 1);

        Election.ElectionWinner[][] memory winners = election.getEachCategoryWinner();
        // candidateOne should have 3 votes for President
        assertEq(winners[0].length, 1);
        assertEq(winners[0][0].electionCandidate.votes, 3);

        // candidateThree should have 2 votes, candidateFour should have 1 vote for VP
        assertEq(winners[1].length, 1);
        assertEq(winners[1][0].electionCandidate.votes, 2);
    }

    // ====================================================================
    // MISSING TESTS - Boundary Conditions
    // ====================================================================

    function testConstructorWithMinimumValidInputs() public {
        // Test with minimal valid inputs (1 candidate, 1 voter, 1 officer, 1 unit, 1 category)
        Election.CandidateInfoDTO[] memory minCandidates = new Election.CandidateInfoDTO[](1);
        minCandidates[0] = candidateOne;

        Election.VoterInfoDTO[] memory minVoters = new Election.VoterInfoDTO[](1);
        minVoters[0] = voterOne;

        address[] memory minOfficers = new address[](1);
        minOfficers[0] = pollingOfficer1;

        address[] memory minUnits = new address[](1);
        minUnits[0] = pollingUnit1;

        string[] memory minCategories = new string[](1);
        minCategories[0] = "President";

        // Election minElection = new Election({
        //     createdBy: creator,
        //     electionUniqueTokenId: ELECTION_TOKEN_ID,
        //     startTimeStamp: startTimestamp,
        //     endTimeStamp: endTimestamp,
        //     electionName: ELECTION_NAME,
        //     candidatesList: minCandidates,
        //     votersList: minVoters,
        //     pollingUnitAddresses: minUnits,
        //     pollingOfficerAddresses: minOfficers,
        //     electionCategories: minCategories
        // });

        Election.ElectionParams memory params = Election.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: minCandidates,
            votersList: minVoters,
            pollingUnitAddresses: minUnits,
            pollingOfficerAddresses: minOfficers,
            electionCategories: minCategories
        });
        Election minElection =
            new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
        assertEq(minElection.getRegisteredVotersCount(), 1);
        assertEq(minElection.getRegisteredCandidatesCount(), 1);
    }
}
