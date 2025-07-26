// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Election, IElection} from "../../src/Election.sol";

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

    IElection.CandidateInfoDTO candidateOne = IElection.CandidateInfoDTO({
        name: "Ayeni Samuel",
        matricNo: "CAND001",
        category: "President",
        voteFor: 1,
        voteAgainst: 0
    });
    IElection.CandidateInfoDTO candidateTwo = IElection.CandidateInfoDTO({
        name: "Leumas Ineya",
        matricNo: "CAND002",
        category: "President",
        voteFor: 1,
        voteAgainst: 0
    });
    IElection.CandidateInfoDTO candidateThree = IElection.CandidateInfoDTO({
        name: "Bob Johnson",
        matricNo: "CAND003",
        category: "Vice President",
        voteFor: 1,
        voteAgainst: 0
    });
    IElection.CandidateInfoDTO candidateFour = IElection.CandidateInfoDTO({
        name: "Nosnhoj Bob",
        matricNo: "CAND004",
        category: "Vice President",
        voteFor: 1,
        voteAgainst: 0
    });
    IElection.CandidateInfoDTO unknownCandidate = IElection.CandidateInfoDTO({
        name: "Unknown Bob",
        matricNo: "CAND0088",
        category: "UNKNOWNGUY",
        voteFor: 1,
        voteAgainst: 0
    });

    IElection.VoterInfoDTO voterOne =
        IElection.VoterInfoDTO({name: "Voter1 Surname", matricNo: "VOT001", department: "Computer Science", level: 100});
    IElection.VoterInfoDTO voterTwo =
        IElection.VoterInfoDTO({name: "Voter2", matricNo: "VOT002", department: "Computer Science", level: 100});
    IElection.VoterInfoDTO voterThree =
        IElection.VoterInfoDTO({name: "Voter3", matricNo: "VOT003", department: "Computer Science", level: 100});
    IElection.VoterInfoDTO voterFour =
        IElection.VoterInfoDTO({name: "Voter4", matricNo: "VOT004", department: "Computer Science", level: 100});
    IElection.VoterInfoDTO voterFive =
        IElection.VoterInfoDTO({name: "Voter5", matricNo: "VOT005", department: "Computer Science", level: 100});
    IElection.VoterInfoDTO unknownVoter =
        IElection.VoterInfoDTO({name: "This Unknown", matricNo: "VOT007", department: "Computer Science", level: 100});

    IElection.CandidateInfoDTO[] candidatesList;
    IElection.VoterInfoDTO[] votersList;
    IElection.PollIdentifier[] pollingOfficerAddresses;
    IElection.PollIdentifier[] pollingUnitAddresses;

    function setUp() public {
        _setupTestData();
        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
        election.addVoters(creator, votersList);
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
        pollingOfficerAddresses.push(
            IElection.PollIdentifier({pollAddress: pollingOfficer1, pollRoleName: "pollingOfficer1"})
        );
        pollingOfficerAddresses.push(
            IElection.PollIdentifier({pollAddress: pollingOfficer2, pollRoleName: "pollingOfficer2"})
        );

        // Setup polling unit addresses
        pollingUnitAddresses.push(IElection.PollIdentifier({pollAddress: pollingUnit1, pollRoleName: "pollingUnit1"}));
        pollingUnitAddresses.push(IElection.PollIdentifier({pollAddress: pollingUnit2, pollRoleName: "pollingUnit2"}));

        //
        electionCategories = ["President", "Vice President"];
        duplicateCat = ["President", "Vice President", "Vice President"];
    }

    // ====================================================================
    // Constructor Tests
    // ====================================================================
    function testElectionIsCreatedWithRightCredentials() public {
        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
        election.addVoters(creator, votersList);
        // Verify basic properties
        assertEq(creator, creator);
        assertEq(election.getElectionUniqueTokenId(), ELECTION_TOKEN_ID);
        assertEq(election.getStartTimeStamp(), startTimestamp);
        assertEq(election.getEndTimeStamp(), endTimestamp);
        assertEq(election.getElectionName(), ELECTION_NAME);
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.OPENED));

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

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: pastTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenInvalidEndTimeStamp() public {
        uint256 invalidEndTimestamp = startTimestamp - 1 hours;

        vm.expectRevert(Election.Election__InvalidEndTimeStamp.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: invalidEndTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    // function testElectionRevertWhenEmptyVotersList() public {
    //     IElection.VoterInfoDTO[] memory emptyVoters;

    //     vm.expectRevert(Election.Election__VoterInfoDTOCannotBeEmpty.selector);

    //     IElection.ElectionParams memory params = IElection.ElectionParams({
    //         startTimeStamp: startTimestamp,
    //         endTimeStamp: endTimestamp,
    //         electionName: ELECTION_NAME,
    //         description: ELECTION_DESCRIPTION,
    //         candidatesList: candidatesList,
    //         pollingUnits: pollingUnitAddresses,
    //         pollingOfficers: pollingOfficerAddresses,
    //         electionCategories: electionCategories
    //     });
    //     election = new Election({
    //         createdBy: creator,
    //         electionUniqueTokenId: ELECTION_TOKEN_ID,
    //         params: params
    //     });
    //     election.addVoters(creator, emptyVoters);
    // }

    function testElectionRevertWhenEmptyCandidatesList() public {
        IElection.CandidateInfoDTO[] memory emptyCandidates;

        vm.expectRevert(Election.Election__CandidatesInfoDTOCannotBeEmpty.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: emptyCandidates,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenEmptyPollingOfficers() public {
        IElection.PollIdentifier[] memory emptyOfficers;

        vm.expectRevert(Election.Election__PollingOfficerAndUnitCannotBeEmpty.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: emptyOfficers,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenEmptyPollingUnits() public {
        IElection.PollIdentifier[] memory emptyPollingUnits;

        vm.expectRevert(Election.Election__PollingOfficerAndUnitCannotBeEmpty.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: emptyPollingUnits,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenCreatorHasMultipleRoles() public {
        // Make creator also a polling officer
        IElection.PollIdentifier[] memory conflictingOfficers = new IElection.PollIdentifier[](1);
        conflictingOfficers[0] = IElection.PollIdentifier({pollAddress: creator, pollRoleName: "creator"});

        vm.expectRevert(Election.Election__AddressCanOnlyHaveOneRole.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: conflictingOfficers,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenCategoryHasDuplicate() public {
        vm.expectRevert(Election.Election__DuplicateCategory.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: duplicateCat
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenDuplicateVoter() public {
        IElection.VoterInfoDTO[] memory duplicateVoters = new IElection.VoterInfoDTO[](2);
        duplicateVoters[0] = voterOne;
        duplicateVoters[1] = voterOne;

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});

        // Register voters
        election.addVoters(creator, votersList);

        vm.expectRevert(abi.encodeWithSelector(Election.Election__DuplicateVoter.selector, voterOne.matricNo));
        // Register some duplicates
        election.addVoters(creator, duplicateVoters);
    }

    function testElectionRevertWhenDuplicateCandidate() public {
        IElection.CandidateInfoDTO[] memory duplicateCandidates = new IElection.CandidateInfoDTO[](2);
        duplicateCandidates[0] = candidateOne;
        duplicateCandidates[1] = candidateOne;

        vm.expectRevert(abi.encodeWithSelector(Election.Election__DuplicateCandidate.selector, candidateOne.matricNo));
        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: duplicateCandidates,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenPollingOfficerIsAlsoPollingUnit() public {
        IElection.PollIdentifier[] memory conflictingUnits = new IElection.PollIdentifier[](1);
        conflictingUnits[0] = IElection.PollIdentifier({pollAddress: pollingOfficer1, pollRoleName: "pollingOfficer1"});

        vm.expectRevert(Election.Election__AddressCanOnlyHaveOneRole.selector);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: conflictingUnits,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    function testElectionRevertWhenCandidateCategoryInvalid() public {
        // Add error Candidate
        candidatesList.push(unknownCandidate);

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            pollingUnits: pollingUnitAddresses,
            pollingOfficers: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        vm.expectRevert(abi.encodeWithSelector(Election.Election__InvalidCategory.selector, "UNKNOWNGUY"));
        election = new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
    }

    // ====================================================================
    // Election State Tests
    // ====================================================================
    function testElectionStateProgressionOverTime() public {
        // Initially OPENED
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.OPENED));

        // Move to start time
        vm.warp(startTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.STARTED));

        // Move to end time
        vm.warp(endTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.ENDED));
    }

    function testUpdateElectionStateFunction() public {
        // Move to start time and update
        vm.warp(startTimestamp);
        election.updateElectionState();
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.STARTED));

        // Move to end time and update
        vm.warp(endTimestamp);
        election.updateElectionState();
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.ENDED));
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
                IElection.ElectionState.STARTED,
                IElection.ElectionState.OPENED
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
                IElection.ElectionState.STARTED,
                IElection.ElectionState.ENDED
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

        vm.expectRevert(abi.encodeWithSelector(Election.Election__OnlyPollingOfficerAllowed.selector, unknownAddress));

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

    function testValidateVoterSuccessWithFirstWordOfFullName() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        election.validateVoterForVoting("Voter1", voterOne.matricNo, pollingUnit1);
    }

    function testValidateVoterFailsWithFullName() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        vm.expectRevert(Election.Election__VoterCannotBeValidated.selector);
        election.validateVoterForVoting(voterOne.name, voterOne.matricNo, pollingUnit1);
    }

    function testVoteCandidatesSuccess() public {
        vm.warp(startTimestamp);

        // First accredite the voter
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Prepare voting candidates
        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateTwo;

        vm.expectEmit(false, false, false, true);
        emit Election.VoterVoted();

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);

        // Verify voted count increased
        assertEq(election.getVotedVotersCount(), 1);
    }

    function testVoteCandidatesRevertWhenElectionNotStarted() public {
        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                IElection.ElectionState.STARTED,
                IElection.ElectionState.OPENED
            )
        );

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenUnknownVoter() public {
        vm.warp(startTimestamp);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(abi.encodeWithSelector(Election.Election__UnknownVoter.selector, unknownVoter.matricNo));

        election.voteCandidates(unknownVoter.matricNo, unknownVoter.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenVoterNotAccredited() public {
        vm.warp(startTimestamp);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](1);
        votingCandidates[0] = candidatesList[0];

        vm.expectRevert(abi.encodeWithSelector(Election.Election__UnaccreditedVoter.selector, voterOne.matricNo));

        election.voteCandidates(voterOne.matricNo, voterOne.name, pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenEmptyCandidatesList() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        IElection.CandidateInfoDTO[] memory emptyCandidates;

        vm.expectRevert(Election.Election__CandidatesInfoDTOCannotBeEmpty.selector);

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, emptyCandidates);
    }

    function testVoteCandidatesRevertWhenVoterNameMismatch() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(Election.Election__VoterCannotBeValidated.selector);

        election.voteCandidates(voterOne.matricNo, "WRONGNAMEEEE", pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenUnauthorizedPollingUnit() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(abi.encodeWithSelector(Election.Election__OnlyPollingUnitAllowed.selector, unknownAddress));

        election.voteCandidates(voterOne.matricNo, "Alice Johnson", unknownAddress, votingCandidates);
    }

    function testVoteCandidatesRevertWhenNotOwner() public {
        vm.warp(startTimestamp);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = candidatesList[2];

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__UnauthorizedAccountOnlyVotsEngineCanCallContract.selector, unknownAddress
            )
        );

        vm.prank(unknownAddress);
        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenInvalidCategoryVoted() public {
        vm.warp(startTimestamp);

        // Accredite voter first
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidatesList[0];
        votingCandidates[1] = unknownCandidate;

        vm.expectRevert(abi.encodeWithSelector(Election.Election__InvalidCategory.selector, unknownCandidate.category));

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesRevertWhenVoterAlreadyVoted() public {
        vm.warp(startTimestamp);

        // Accredite and vote first time
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateThree;

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);

        // Try to vote again
        vm.expectRevert(abi.encodeWithSelector(Election.Election__VoterAlreadyVoted.selector));
        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit2, votingCandidates);
    }

    function testVoteCandidatesRevertWhenIncorrectCategoryCount() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        // Only vote for 1 category when 2 are required
        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](1);
        votingCandidates[0] = candidateOne;

        vm.expectRevert(Election.Election__AllCategoriesMustHaveOnlyOneVotedCandidate.selector);
        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);
    }

    function testVoteCandidatesMultipleVotersSuccess() public {
        vm.warp(startTimestamp);

        // Accredite multiple voters
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateThree;

        // Vote with both voters
        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);
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

    function testGetAllVotersReturnsCorrectData() public {
        vm.warp(endTimestamp + 1);
        Election.ElectionVoter[] memory allVoters = election.getAllVoters();
        assertEq(allVoters.length, votersList.length);

        // Check first voter data
        assertEq(allVoters[0].name, voterOne.name);
        assertEq(uint256(allVoters[0].voterState), uint256(IElection.VoterState.REGISTERED));
    }

    function testGetAllAccreditedVotersInitiallyEmpty() public {
        vm.warp(endTimestamp + 1);
        Election.ElectionVoter[] memory accreditedVoters = election.getAllAccreditedVoters();
        assertEq(accreditedVoters.length, 0);
    }

    function testGetAllAccreditedVotersAfterAccreditation() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        vm.warp(endTimestamp + 1);
        Election.ElectionVoter[] memory accreditedVoters = election.getAllAccreditedVoters();
        assertEq(accreditedVoters.length, 1);
        assertEq(accreditedVoters[0].name, voterOne.name);
        assertEq(uint256(accreditedVoters[0].voterState), uint256(IElection.VoterState.ACCREDITED));
    }

    function testGetAllVotedVotersInitiallyEmpty() public {
        vm.warp(endTimestamp + 1);
        Election.ElectionVoter[] memory votedVoters = election.getAllVotedVoters();
        assertEq(votedVoters.length, 0);
    }

    function testGetAllVotedVotersAfterVoting() public {
        vm.warp(startTimestamp);
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);

        IElection.CandidateInfoDTO[] memory votingCandidates = new IElection.CandidateInfoDTO[](2);
        votingCandidates[0] = candidateOne;
        votingCandidates[1] = candidateThree;

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, votingCandidates);

        vm.warp(endTimestamp + 1);
        Election.ElectionVoter[] memory votedVoters = election.getAllVotedVoters();
        assertEq(votedVoters.length, 1);
        assertEq(votedVoters[0].name, voterOne.name);
        assertEq(uint256(votedVoters[0].voterState), uint256(IElection.VoterState.VOTED));
    }

    function testGetAllCandidatesInDto() public view {
        IElection.CandidateInfoDTO[] memory candidates = election.getAllCandidatesInDto();
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
                IElection.ElectionState.ENDED,
                IElection.ElectionState.OPENED
            )
        );
        election.getAllCandidates();
    }

    function testGetAllCandidatesAfterElectionEnds() public {
        vm.warp(endTimestamp + 1); // Election ended

        Election.CandidateInfoDTO[] memory candidates = election.getAllCandidates();
        assertEq(candidates.length, candidatesList.length);
    }

    function testGetEachCategoryWinnerRevertWhenElectionNotEnded() public {
        vm.warp(startTimestamp);

        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                IElection.ElectionState.ENDED,
                IElection.ElectionState.OPENED
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

        IElection.CandidateInfoDTO[] memory vote1 = new IElection.CandidateInfoDTO[](2);
        vote1[0] = candidateOne; // President
        vote1[1] = candidateThree; // VicePresident

        IElection.CandidateInfoDTO[] memory vote2 = new IElection.CandidateInfoDTO[](2);
        vote2[0] = candidateOne; // President (same)
        vote2[1] = candidateFour; // VicePresident (different)

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, vote1);
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

        IElection.CandidateInfoDTO[] memory vote1 = new IElection.CandidateInfoDTO[](2);
        vote1[0] = candidateOne;
        vote1[1] = candidateThree;

        IElection.CandidateInfoDTO[] memory vote2 = new IElection.CandidateInfoDTO[](2);
        vote2[0] = candidateTwo; // Different president candidate
        vote2[1] = candidateFour; // Different VP candidate

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, vote1);
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
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.STARTED));

        // Test one second before end
        vm.warp(endTimestamp - 1);
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.STARTED));

        // Test at exact end timestamp
        vm.warp(endTimestamp);
        assertEq(uint256(election.getElectionState()), uint256(IElection.ElectionState.ENDED));
    }

    function testVoteCountingAccuracy() public {
        vm.warp(startTimestamp);

        // Accredite 3 voters
        election.accrediteVoter(voterOne.matricNo, pollingOfficer1);
        election.accrediteVoter(voterTwo.matricNo, pollingOfficer2);
        election.accrediteVoter(voterThree.matricNo, pollingOfficer1);

        // All vote for candidateOne for President, different for VP
        IElection.CandidateInfoDTO[] memory vote1 = new IElection.CandidateInfoDTO[](2);
        vote1[0] = candidateOne;
        vote1[1] = candidateThree;

        IElection.CandidateInfoDTO[] memory vote2 = new IElection.CandidateInfoDTO[](2);
        vote2[0] = candidateOne;
        vote2[1] = candidateThree;

        IElection.CandidateInfoDTO[] memory vote3 = new IElection.CandidateInfoDTO[](2);
        vote3[0] = candidateOne;
        vote3[1] = candidateFour;

        election.voteCandidates(voterOne.matricNo, "Voter1", pollingUnit1, vote1);
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
        IElection.CandidateInfoDTO[] memory minCandidates = new IElection.CandidateInfoDTO[](1);
        minCandidates[0] = candidateOne;

        IElection.VoterInfoDTO[] memory minVoters = new IElection.VoterInfoDTO[](1);
        minVoters[0] = voterOne;

        IElection.PollIdentifier[] memory minOfficers = new IElection.PollIdentifier[](1);
        minOfficers[0] = IElection.PollIdentifier({pollAddress: pollingOfficer1, pollRoleName: "pollingOfficer1"});

        IElection.PollIdentifier[] memory minUnits = new IElection.PollIdentifier[](1);
        minUnits[0] = IElection.PollIdentifier({pollAddress: pollingUnit1, pollRoleName: "pollingUnit1"});

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
        //     pollingUnits: minUnits,
        //     pollingOfficers: minOfficers,
        //     electionCategories: minCategories
        // });

        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: minCandidates,
            pollingUnits: minUnits,
            pollingOfficers: minOfficers,
            electionCategories: minCategories
        });
        Election minElection =
            new Election({createdBy: creator, electionUniqueTokenId: ELECTION_TOKEN_ID, params: params});
        minElection.addVoters(creator, minVoters);
        assertEq(minElection.getRegisteredVotersCount(), 1);
        assertEq(minElection.getRegisteredCandidatesCount(), 1);
    }

    function test_AddLargeAmountOfVotersWorksInBatches(uint256 votersLength) public {
        votersLength = bound(votersLength, 2000, 3000);
        console.log("Voters length", votersLength);
        uint256 batchNum = election.getVotersBatchLimit();
        uint256 totalRun = votersLength / batchNum;

        console.log("totalRun", totalRun);
        for (uint256 index = 0; index <= totalRun; index++) {
            uint256 startNum = index * batchNum;
            uint256 endNum = startNum + batchNum;

            console.log("current run, $start, $end", index, startNum, endNum);
            _registerBatch(startNum, endNum, election);
        }
    }

    function test_AddLargeAmountOfVotersRevertsWhenGreaterThanBatches(uint256 votersLength) public {
        uint256 batchLimit = election.getVotersBatchLimit();
        votersLength = bound(votersLength, batchLimit + 1, batchLimit + 200);

        IElection.VoterInfoDTO[] memory fuzzVoters = new IElection.VoterInfoDTO[](votersLength);

        for (uint256 i = 0; i < votersLength; i++) {
            fuzzVoters[i] = IElection.VoterInfoDTO({
                name: string(abi.encodePacked("FuzzVoter", vm.toString(i))),
                matricNo: string(abi.encodePacked("FUZZ", vm.toString(i))),
                department: string(abi.encodePacked("Department", vm.toString(i % 5))),
                level: 100 + (i % 400)
            });
        }

        vm.expectRevert(
            abi.encodeWithSelector(Election.Election__VoterInfoListAboveBatchLimit.selector, batchLimit, votersLength)
        );

        election.addVoters(creator, fuzzVoters);
    }

    function _registerBatch(uint256 start, uint256 end, Election injectedElection) public {
        uint256 batchSize = end - start;
        IElection.VoterInfoDTO[] memory fuzzVoters = new IElection.VoterInfoDTO[](batchSize);

        for (uint256 j = 0; j < batchSize; j++) {
            uint256 globalIndex = start + j;
            string memory addedString = vm.toString(globalIndex);

            fuzzVoters[j] = IElection.VoterInfoDTO({
                name: string(abi.encodePacked("FuzzVoter", addedString)),
                matricNo: string(abi.encodePacked("FUZZ", addedString)),
                department: string(abi.encodePacked("Department", addedString)),
                level: 100 + (globalIndex % 400)
            });
        }

        uint256 initialVoterCount = injectedElection.getRegisteredVotersCount();
        injectedElection.addVoters(creator, fuzzVoters);

        assertEq(injectedElection.getRegisteredVotersCount(), initialVoterCount + batchSize);

        IElection.ElectionVoter[] memory allVoters = injectedElection.getAllVoters();

        for (uint256 j = 0; j < batchSize; j++) {
            uint256 voterIndex = initialVoterCount + j;
            assertEq(allVoters[voterIndex].name, fuzzVoters[j].name);
            assertEq(allVoters[voterIndex].department, fuzzVoters[j].department);
            assertEq(allVoters[voterIndex].level, fuzzVoters[j].level);
            assertEq(uint256(allVoters[voterIndex].voterState), uint256(IElection.VoterState.REGISTERED));
        }
    }
}
