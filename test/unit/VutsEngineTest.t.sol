// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VutsEngine, Election} from "../../src/VutsEngine.sol";
import {DeployVutsEngine} from "../../script/DeployVutsEngine.s.sol";

contract VutsEngineTest is Test {
    VutsEngine public vutsEngine;
    DeployVutsEngine public deployVutsEngine;

    address public creator = makeAddr("creator");
    address public creator2 = makeAddr("creator2");
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
        _setupTestData();
        deployVutsEngine = new DeployVutsEngine();
        vutsEngine = deployVutsEngine.run();
    }

    function _setupTestData() internal {
        // Set timestamps relative to current time
        startTimestamp = block.timestamp + 1 days;
        endTimestamp = startTimestamp + 7 days;

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
    }

    // ====================================================================
    // Election Creation Tests
    // ====================================================================

    function testCreateElectionSuccess() public {
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        // Verify election was created
        assertTrue(vutsEngine.electionExists(ELECTION_NAME));
        assertEq(vutsEngine.getTotalElectionsCount(), 1);

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);
        assertEq(tokenId, 1);

        address electionAddress = vutsEngine.getElectionAddress(tokenId);
        assertTrue(electionAddress != address(0));
    }

    function testCreateElectionEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit VutsEngine.ElectionContractedCreated(1, ELECTION_NAME);

        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );
    }

    function testCreateElectionRevertOnDuplicateName() public {
        // Create first election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        // Try to create duplicate
        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__DuplicateElectionName.selector,
                ELECTION_NAME
            )
        );

        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp + 10 days,
            endTimestamp + 10 days,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );
    }

    function testCreateMultipleElections() public {
        // Create first election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            "Election 1",
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        // Create second election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp + 10 days,
            endTimestamp + 10 days,
            "Election 2",
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        assertEq(vutsEngine.getTotalElectionsCount(), 2);
        assertTrue(vutsEngine.electionExists("Election 1"));
        assertTrue(vutsEngine.electionExists("Election 2"));
    }

    function testCreateElectionRevertOnEmptyElectionName() public {
        vm.expectRevert(
            VutsEngine.VutsEngine__ElectionNameCannotBeEmpty.selector
        );
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            "",
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );
    }

    // ====================================================================
    // Voter Accreditation Tests
    // ====================================================================

    function testAccrediteVoterSuccess() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election
        vm.warp(startTimestamp + 1);

        // Accredite voter
        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        // Verify accreditation
        assertEq(vutsEngine.getAccreditedVotersCount(tokenId), 1);
    }

    function testAccrediteVoterRevertOnInvalidPollingOfficer() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election
        vm.warp(startTimestamp + 1);

        // Try to accredite with invalid officer
        vm.expectRevert(Election.Election__OnlyPollingOfficerAllowed.selector);
        vm.prank(unknownAddress); // user2 is not a polling officer
        vutsEngine.accrediteVoter(voterFive.name, tokenId);
    }

    function testAccrediteVoterRevertOnInvalidElection() public {
        uint256 invalidTokenId = 999;

        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                invalidTokenId
            )
        );

        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.name, invalidTokenId);
    }

    function testAccrediteVoterRevertBeforeElectionStart() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Try to accredite before election starts
        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.STARTED,
                Election.ElectionState.OPENED
            )
        );

        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.name, tokenId);
    }

    // ====================================================================
    // Voting Tests
    // ====================================================================

    function testVoteCandidatesSuccess() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election and accredite voter
        vm.warp(startTimestamp + 1);
        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        // Prepare vote
        Election.CandidateInfoDTO[]
            memory votes = new Election.CandidateInfoDTO[](2);
        votes[0] = candidateOne;
        votes[1] = candidateThree;

        // Cast vote
        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            votes,
            tokenId
        );

        // Verify vote was cast
        assertEq(vutsEngine.getVotedVotersCount(tokenId), 1);
    }

    function testVoteCandidatesRevertOnInvalidPollingUnit() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election and accredite voter
        vm.warp(startTimestamp + 1);
        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        // Prepare vote
        Election.CandidateInfoDTO[]
            memory votes = new Election.CandidateInfoDTO[](2);

        votes[0] = candidateOne;
        votes[1] = candidateThree;

        // Try to vote with invalid polling unit
        vm.expectRevert(Election.Election__OnlyPollingUnitAllowed.selector);
        vm.prank(creator); // creator is not a polling unit
        vutsEngine.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            votes,
            tokenId
        );
    }

    function testVoteCandidatesRevertOnUnaccreditedVoter() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election (don't accredite voter)
        vm.warp(startTimestamp + 1);

        // Prepare vote
        Election.CandidateInfoDTO[]
            memory votes = new Election.CandidateInfoDTO[](2);

        votes[0] = candidateOne;
        votes[1] = candidateThree;

        // Try to vote without accreditation
        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__UnaccreditedVoter.selector,
                voterFive.matricNo
            )
        );
        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterFive.matricNo,
            voterFive.name,
            votes,
            tokenId
        );
    }

    // ====================================================================
    // Getter Function Tests
    // ====================================================================

    function testGetElectionInfo() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        (
            address createdBy,
            string memory electionName,
            uint256 startTs,
            uint256 endTs,
            Election.ElectionState state
        ) = vutsEngine.getElectionInfo(tokenId);

        assertEq(createdBy, creator);
        assertEq(electionName, ELECTION_NAME);
        assertEq(startTs, startTimestamp);
        assertEq(endTs, endTimestamp);
        assertEq(uint(state), uint(Election.ElectionState.OPENED));
    }

    function testGetElectionStats() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        (
            uint256 registeredVotersCount,
            uint256 accreditedVotersCount,
            uint256 votedVotersCount,
            uint256 registeredCandidatesCount,
            uint256 pollingOfficerCount,
            uint256 pollingUnitCount
        ) = vutsEngine.getElectionStats(tokenId);

        assertEq(registeredVotersCount, votersList.length);
        assertEq(accreditedVotersCount, 0);
        assertEq(votedVotersCount, 0);
        assertEq(registeredCandidatesCount, candidatesList.length);
        assertEq(pollingOfficerCount, 2);
        assertEq(pollingUnitCount, 2);
    }

    function testGetAllVoters() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        Election.ElectionVoter[] memory voters = vutsEngine.getAllVoters(
            tokenId
        );

        assertEq(voters.length, votersList.length);
        assertEq(voters[0].name, voterOne.name);
        assertEq(
            uint(voters[0].voterState),
            uint(Election.VoterState.REGISTERED)
        );
    }

    function testGetAllCandidatesInDto() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        Election.CandidateInfoDTO[] memory candidates = vutsEngine
            .getAllCandidatesInDto(tokenId);

        assertEq(candidates.length, 4);
        assertEq(candidates[0].name, candidateOne.name);
        assertEq(candidates[0].matricNo, candidateOne.matricNo);
        assertEq(candidates[0].category, candidateOne.category);
    }

    function testGetAllElectionsSummary() public {
        // Create multiple elections
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            "Election 1",
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        vm.prank(creator2);
        vutsEngine.createElection(
            startTimestamp + 10 days,
            endTimestamp + 10 days,
            "Election 2",
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        VutsEngine.ElectionSummary[] memory summaries = vutsEngine
            .getAllElectionsSummary();

        assertEq(summaries.length, 2);
        assertEq(summaries[0].electionId, 1);
        assertEq(summaries[0].electionName, "Election 1");
        assertEq(summaries[1].electionId, 2);
        assertEq(summaries[1].electionName, "Election 2");
    }

    function testGetElectionInfoRevertOnInvalidTokenId() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                999
            )
        );
        vutsEngine.getElectionInfo(999);
    }

    function testGetElectionStatsRevertOnInvalidTokenId() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                999
            )
        );
        vutsEngine.getElectionStats(999);
    }

    function testGetAllVotersRevertOnInvalidTokenId() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                999
            )
        );
        vutsEngine.getAllVoters(999);
    }

    function testGetAllCandidatesInDtoRevertOnInvalidTokenId() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                999
            )
        );
        vutsEngine.getAllCandidatesInDto(999);
    }

    function testGetEachCategoryWinnerRevertOnInvalidTokenId() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                999
            )
        );
        vutsEngine.getEachCategoryWinner(999);
    }

    // ====================================================================
    // Zero Token ID Edge Case
    // ====================================================================

    function testElectionTokenIdZeroHandling() public {
        // Test that token ID 0 is treated as non-existent
        assertFalse(vutsEngine.electionExistsByTokenId(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                VutsEngine.VutsEngine__ElectionContractNotFound.selector,
                0
            )
        );
        vutsEngine.getElectionAddress(0);
    }

    // ====================================================================
    // Results Tests (After Election Ends)
    // ====================================================================

    function testGetElectionResultsAfterElectionEnds() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election, accredite voters, and cast votes
        vm.warp(startTimestamp + 1);

        // Accredite and vote for multiple voters
        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterTwo.matricNo, tokenId);

        // Vote 1
        Election.CandidateInfoDTO[]
            memory votes1 = new Election.CandidateInfoDTO[](2);

        votes1[0] = candidateOne;
        votes1[1] = candidateThree;

        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            votes1,
            tokenId
        );

        // Vote 2
        Election.CandidateInfoDTO[]
            memory votes2 = new Election.CandidateInfoDTO[](2);

        votes2[0] = candidateOne;
        votes2[1] = candidateFour;

        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterTwo.matricNo,
            voterTwo.name,
            votes2,
            tokenId
        );

        // End election
        vm.warp(endTimestamp + 1);

        // Get results
        Election.ElectionCandidate[] memory allCandidates = vutsEngine
            .getAllCandidates(tokenId);
        Election.ElectionWinner[][] memory winners = vutsEngine
            .getEachCategoryWinner(tokenId);

        // Verify results
        assertTrue(allCandidates.length > 0);
        assertEq(winners.length, 2); // Two categories

        // John Doe should win President with 2 votes
        assertEq(winners[0].length, 1);
        assertEq(winners[0][0].matricNo, candidateOne.matricNo);
        assertEq(winners[0][0].electionCandidate.votes, 2);

        // Vice President should have a tie (1 vote each)
        assertEq(winners[1].length, 2);
    }

    function testGetResultsRevertBeforeElectionEnds() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Try to get results before election ends
        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                Election.ElectionState.ENDED,
                Election.ElectionState.OPENED
            )
        );
        vutsEngine.getAllCandidates(tokenId);
    }

    // ====================================================================
    // State Management Tests
    // ====================================================================

    function testUpdateElectionState() public {
        // Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // Initially OPENED
        (, , , , Election.ElectionState state) = vutsEngine.getElectionInfo(
            tokenId
        );
        assertEq(uint(state), uint(Election.ElectionState.OPENED));

        // Move to STARTED
        vm.warp(startTimestamp + 1);
        vutsEngine.updateElectionState(tokenId);
        (, , , , state) = vutsEngine.getElectionInfo(tokenId);
        assertEq(uint(state), uint(Election.ElectionState.STARTED));

        // Move to ENDED
        vm.warp(endTimestamp + 1);
        vutsEngine.updateElectionState(tokenId);
        (, , , , state) = vutsEngine.getElectionInfo(tokenId);
        assertEq(uint(state), uint(Election.ElectionState.ENDED));
    }

    // ====================================================================
    // Integration Test - Full Election Flow
    // ====================================================================

    function testFullElectionFlow() public {
        // 1. Create election
        vm.prank(creator);
        vutsEngine.createElection(
            startTimestamp,
            endTimestamp,
            ELECTION_NAME,
            candidatesList,
            votersList,
            pollingUnitAddresses,
            pollingOfficerAddresses,
            electionCategories
        );

        uint256 tokenId = vutsEngine.getElectionTokenId(ELECTION_NAME);

        // 2. Verify initial state
        assertEq(
            vutsEngine.getRegisteredVotersCount(tokenId),
            votersList.length
        );
        assertEq(
            vutsEngine.getRegisteredCandidatesCount(tokenId),
            candidatesList.length
        );
        assertEq(vutsEngine.getAccreditedVotersCount(tokenId), 0);
        assertEq(vutsEngine.getVotedVotersCount(tokenId), 0);

        // 3. Start election
        vm.warp(startTimestamp + 1);

        // 4. Accredite all voters
        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        vm.prank(pollingOfficer2);
        vutsEngine.accrediteVoter(voterTwo.matricNo, tokenId);

        vm.prank(pollingOfficer1);
        vutsEngine.accrediteVoter(voterThree.matricNo, tokenId);
        vm.prank(pollingOfficer2);
        vutsEngine.accrediteVoter(voterFour.matricNo, tokenId);

        assertEq(vutsEngine.getAccreditedVotersCount(tokenId), 4);

        // 5. Cast votes
        Election.CandidateInfoDTO[]
            memory votes = new Election.CandidateInfoDTO[](2);

        votes[0] = candidateOne;
        votes[1] = candidateThree;

        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterOne.matricNo,
            voterOne.name,
            votes,
            tokenId
        );

        vm.prank(pollingUnit2);
        vutsEngine.voteCandidates(
            voterTwo.matricNo,
            voterTwo.name,
            votes,
            tokenId
        );

        votes[0] = candidateTwo;
        votes[1] = candidateFour;

        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterThree.matricNo,
            voterThree.name,
            votes,
            tokenId
        );
        votes[0] = candidateOne;
        votes[1] = candidateFour;

        vm.prank(pollingUnit1);
        vutsEngine.voteCandidates(
            voterFour.matricNo,
            voterFour.name,
            votes,
            tokenId
        );

        assertEq(vutsEngine.getVotedVotersCount(tokenId), 4);

        // 6. End election and check results
        vm.warp(endTimestamp + 1);

        Election.ElectionWinner[][] memory winners = vutsEngine
            .getEachCategoryWinner(tokenId);

        // President: John Doe should win with 2 votes
        assertEq(winners[0].length, 1);
        assertEq(winners[0][0].matricNo, candidateOne.matricNo);
        assertEq(winners[0][0].electionCandidate.votes, 3);

        // Vice President: Should be a tie with 1 vote each
        assertEq(winners[1].length, 2);
    }
}
