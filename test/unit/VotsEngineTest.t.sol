// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VotsEngine, IVotsEngine} from "../../src/VotsEngine.sol";
import {Election, IElection} from "../../src/Election.sol";
import {DeployVotsEngine} from "../../script/DeployVotsEngine.s.sol";

contract VotsEngineTest is Test {
    VotsEngine public votsEngine;
    DeployVotsEngine public deployVotsEngine;

    address public creator = makeAddr("creator");
    address public creator2 = makeAddr("creator2");
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
    IElection.CandidateInfoDTO candidateFive = IElection.CandidateInfoDTO({
        name: "TEst Bob",
        matricNo: "CAND005",
        category: "General Secretary",
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

    IElection.VoterInfoDTO voterOne = IElection.VoterInfoDTO({name: "Voter1", matricNo: "VOT001"});
    IElection.VoterInfoDTO voterTwo = IElection.VoterInfoDTO({name: "Voter2", matricNo: "VOT002"});
    IElection.VoterInfoDTO voterThree = IElection.VoterInfoDTO({name: "Voter3", matricNo: "VOT003"});
    IElection.VoterInfoDTO voterFour = IElection.VoterInfoDTO({name: "Voter4", matricNo: "VOT004"});
    IElection.VoterInfoDTO voterFive = IElection.VoterInfoDTO({name: "Voter5", matricNo: "VOT005"});
    IElection.VoterInfoDTO unknownVoter = IElection.VoterInfoDTO({name: "This Unknown", matricNo: "VOT007"});

    IElection.CandidateInfoDTO[] candidatesList;
    IElection.VoterInfoDTO[] votersList;
    address[] pollingOfficerAddresses;
    address[] pollingUnitAddresses;

    function setUp() public {
        _setupTestData();
        deployVotsEngine = new DeployVotsEngine();
        votsEngine = VotsEngine(address(deployVotsEngine.run()));
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
        electionCategories = ["President", "Vice President"];
        duplicateCat = ["President", "Vice President", "Vice President"];
    }

    function _createElectionWithDefaultValues() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories
    }

    // ====================================================================
    // Election Creation Tests
    // ====================================================================

    function testCreateElectionSuccess() public {
        vm.prank(creator);

        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        // Verify election was created
        // assertTrue(votsEngine.electionExists(ELECTION_NAME));
        assertEq(votsEngine.getTotalElectionsCount(), 1);

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);
        assertEq(tokenId, 1);

        address electionAddress = votsEngine.getElectionAddress(tokenId);
        assertTrue(electionAddress != address(0));
    }

    function testCreateElectionEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit IVotsEngine.ElectionContractedCreated(1, ELECTION_NAME);

        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories
    }

    function testCreateElectionRevertOnDuplicateName() public {
        vm.prank(creator);
        // Create first election
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        // Try to create duplicate
        vm.expectRevert(IVotsEngine.VotsEngine__DuplicateElectionName.selector);

        vm.prank(creator);
        IElection.ElectionParams memory secondParams = IElection.ElectionParams({
            startTimeStamp: startTimestamp + 10 days,
            endTimeStamp: endTimestamp + 10 days,
            electionName: ELECTION_NAME,
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        votsEngine.createElection(secondParams);
        // startTimestamp + 10 days,
        // endTimestamp + 10 days,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories
    }

    function testCreateMultipleElections() public {
        // Create first election
        vm.startPrank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: "Election 1",
            candidatesList: candidatesList,
            description: ELECTION_DESCRIPTION,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // "Election 1",
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        // Create second election

        IElection.ElectionParams memory secondParams = IElection.ElectionParams({
            startTimeStamp: startTimestamp + 10 days,
            endTimeStamp: endTimestamp + 10 days,
            electionName: "Election 2",
            candidatesList: candidatesList,
            description: ELECTION_DESCRIPTION,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        votsEngine.createElection(secondParams);
        // startTimestamp + 10 days,
        // endTimestamp + 10 days,
        // "Election 2",
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        vm.stopPrank();
        assertEq(votsEngine.getTotalElectionsCount(), 2);
        assertTrue(votsEngine.electionExistsByTokenId(votsEngine.getElectionTokenId("Election 1")));
        assertTrue(votsEngine.electionExistsByTokenId(votsEngine.getElectionTokenId("Election 2")));
    }

    function testCreateElectionRevertOnEmptyElectionName() public {
        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNameCannotBeEmpty.selector);
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: "",
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // "",
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories
    }

    // ====================================================================
    // Voter Accreditation Tests
    // ====================================================================

    function testAccrediteVoterSuccess() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election
        vm.warp(startTimestamp + 1);

        // Accredite voter
        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        // Verify accreditation
        assertEq(IElection(votsEngine.getElectionAddress(tokenId)).getAccreditedVotersCount(), 1);
    }

    function testAccrediteVoterRevertOnInvalidPollingOfficer() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election
        vm.warp(startTimestamp + 1);

        // Try to accredite with invalid officer
        vm.expectRevert(abi.encodeWithSelector(Election.Election__OnlyPollingOfficerAllowed.selector, unknownAddress));
        vm.prank(unknownAddress); // user2 is not a polling officer
        votsEngine.accrediteVoter(voterFive.name, tokenId);
    }

    function testAccrediteVoterRevertOnInvalidElection() public {
        uint256 invalidTokenId = 999;

        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);

        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.name, invalidTokenId);
    }

    function testAccrediteVoterRevertBeforeElectionStart() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Try to accredite before election starts
        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                IElection.ElectionState.STARTED,
                IElection.ElectionState.OPENED
            )
        );

        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.name, tokenId);
    }

    // ====================================================================
    // Voting Tests
    // ====================================================================

    function testVoteCandidatesSuccess() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election and accredite voter
        vm.warp(startTimestamp + 1);
        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        // Prepare vote
        IElection.CandidateInfoDTO[] memory votes = new IElection.CandidateInfoDTO[](2);
        votes[0] = candidateOne;
        votes[1] = candidateThree;

        // Cast vote
        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterOne.matricNo, voterOne.name, votes, tokenId);

        // Verify vote was cast
        assertEq(IElection(votsEngine.getElectionAddress(tokenId)).getVotedVotersCount(), 1);
    }

    function testVoteCandidatesRevertOnInvalidPollingUnit() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election and accredite voter
        vm.warp(startTimestamp + 1);
        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        // Prepare vote
        IElection.CandidateInfoDTO[] memory votes = new IElection.CandidateInfoDTO[](2);

        votes[0] = candidateOne;
        votes[1] = candidateThree;

        // Try to vote with invalid polling unit
        vm.expectRevert(abi.encodeWithSelector(Election.Election__OnlyPollingUnitAllowed.selector, creator));
        vm.prank(creator); // creator is not a polling unit
        votsEngine.voteCandidates(voterOne.matricNo, voterOne.name, votes, tokenId);
    }

    function testVoteCandidatesRevertOnUnaccreditedVoter() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election (don't accredite voter)
        vm.warp(startTimestamp + 1);

        // Prepare vote
        IElection.CandidateInfoDTO[] memory votes = new IElection.CandidateInfoDTO[](2);

        votes[0] = candidateOne;
        votes[1] = candidateThree;

        // Try to vote without accreditation
        vm.expectRevert(abi.encodeWithSelector(Election.Election__UnaccreditedVoter.selector, voterFive.matricNo));
        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterFive.matricNo, voterFive.name, votes, tokenId);
    }

    // ====================================================================
    // Getter Function Tests
    // ====================================================================

    function testGetElectionInfo() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        VotsEngine.ElectionInfo memory electionInfo = votsEngine.getElectionInfo(tokenId);

        assertEq(electionInfo.createdBy, creator);
        assertEq(electionInfo.electionName, ELECTION_NAME);
        assertEq(electionInfo.startTimestamp, startTimestamp);
        assertEq(electionInfo.endTimestamp, endTimestamp);
        assertEq(uint256(electionInfo.state), uint256(IElection.ElectionState.OPENED));
    }

    function testGetElectionStats() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        (
            uint256 registeredVotersCount,
            uint256 accreditedVotersCount,
            uint256 votedVotersCount,
            uint256 registeredCandidatesCount,
            uint256 pollingOfficerCount,
            uint256 pollingUnitCount
        ) = votsEngine.getElectionStats(tokenId);

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
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        IElection.ElectionVoter[] memory voters = votsEngine.getAllVoters(tokenId);

        assertEq(voters.length, votersList.length);
        assertEq(voters[0].name, voterOne.name);
        assertEq(uint256(voters[0].voterState), uint256(IElection.VoterState.REGISTERED));
    }

    function testGetAllCandidatesInDto() public {
        candidatesList.push(candidateFive);

        electionCategories = ["President", "Vice President", "General Secretary"];
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        IElection.CandidateInfoDTO[] memory candidates = votsEngine.getAllCandidatesInDto(tokenId);

        assertEq(candidates.length, 5);
        assertEq(candidates[0].name, candidateOne.name);
        assertEq(candidates[0].matricNo, candidateOne.matricNo);
        assertEq(candidates[0].category, candidateOne.category);
        console.log("candidates[0].name, candidateOne.name", candidates[0].name, candidateOne.name);

        assertEq(candidates[1].name, candidateTwo.name);
        assertEq(candidates[1].matricNo, candidateTwo.matricNo);
        assertEq(candidates[1].category, candidateTwo.category);
        console.log("candidates[1].name, candidateTwo.name", candidates[1].name, candidateTwo.name);

        assertEq(candidates[2].name, candidateThree.name);
        assertEq(candidates[2].matricNo, candidateThree.matricNo);
        assertEq(candidates[2].category, candidateThree.category);
        console.log("candidates[2].name, candidateThree.name", candidates[2].name, candidateThree.name);

        assertEq(candidates[3].name, candidateFour.name);
        assertEq(candidates[3].matricNo, candidateFour.matricNo);
        assertEq(candidates[3].category, candidateFour.category);
        console.log("candidates[3].name, candidateFour.name", candidates[3].name, candidateFour.name);

        assertEq(candidates[4].name, candidateFive.name);
        assertEq(candidates[4].matricNo, candidateFive.matricNo);
        assertEq(candidates[4].category, candidateFive.category);
        console.log("candidates[4].name, candidateFive.name", candidates[4].name, candidateFour.name);
    }

    function testGetAllElectionsSummary() public {
        // Create multiple elections
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
            startTimeStamp: startTimestamp,
            endTimeStamp: endTimestamp,
            electionName: "Election 1",
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // "Election 1",
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        vm.prank(creator2);
        IElection.ElectionParams memory secondParams = IElection.ElectionParams({
            startTimeStamp: startTimestamp + 10 days,
            endTimeStamp: endTimestamp + 10 days,
            electionName: "Election 2",
            description: ELECTION_DESCRIPTION,
            candidatesList: candidatesList,
            votersList: votersList,
            pollingUnitAddresses: pollingUnitAddresses,
            pollingOfficerAddresses: pollingOfficerAddresses,
            electionCategories: electionCategories
        });

        votsEngine.createElection(secondParams);
        // startTimestamp + 10 days,
        // endTimestamp + 10 days,
        // "Election 2",
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        VotsEngine.ElectionSummary[] memory summaries = votsEngine.getAllElectionsSummary();

        assertEq(summaries.length, 2);
        assertEq(summaries[0].electionId, 1);
        assertEq(summaries[0].electionName, "Election 1");
        assertEq(summaries[1].electionId, 2);
        assertEq(summaries[1].electionName, "Election 2");
    }

    function testGetElectionInfoRevertOnInvalidTokenId() public {
        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);
        votsEngine.getElectionInfo(999);
    }

    function testGetElectionStatsRevertOnInvalidTokenId() public {
        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);
        votsEngine.getElectionStats(999);
    }

    function testGetAllVotersRevertOnInvalidTokenId() public {
        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);
        votsEngine.getAllVoters(999);
    }

    function testGetAllCandidatesInDtoRevertOnInvalidTokenId() public {
        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);
        votsEngine.getAllCandidatesInDto(999);
    }

    function testGetEachCategoryWinnerRevertOnInvalidTokenId() public {
        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);
        votsEngine.getEachCategoryWinner(999);
    }

    // ====================================================================
    // Zero Token ID Edge Case
    // ====================================================================

    function testElectionTokenIdZeroHandling() public {
        // Test that token ID 0 is treated as non-existent
        assertFalse(votsEngine.electionExistsByTokenId(0));

        vm.expectRevert(IVotsEngine.VotsEngine__ElectionNotFound.selector);
        votsEngine.getElectionAddress(0);
    }

    // ====================================================================
    // Results Tests (After Election Ends)
    // ====================================================================

    function testGetElectionResultsAfterElectionEnds() public {
        // Create election
        vm.prank(creator);
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Start election, accredite voters, and cast votes
        vm.warp(startTimestamp + 1);

        // Accredite and vote for multiple voters
        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterTwo.matricNo, tokenId);

        // Vote 1
        IElection.CandidateInfoDTO[] memory votes1 = new IElection.CandidateInfoDTO[](2);

        votes1[0] = candidateOne;
        votes1[1] = candidateThree;

        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterOne.matricNo, voterOne.name, votes1, tokenId);

        // Vote 2
        IElection.CandidateInfoDTO[] memory votes2 = new IElection.CandidateInfoDTO[](2);

        votes2[0] = candidateOne;
        votes2[1] = candidateFour;

        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterTwo.matricNo, voterTwo.name, votes2, tokenId);

        // End election
        vm.warp(endTimestamp + 1);

        // Get results
        Election.ElectionCandidate[] memory allCandidates = votsEngine.getAllCandidates(tokenId);
        Election.ElectionWinner[][] memory winners = votsEngine.getEachCategoryWinner(tokenId);

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
        IElection.ElectionParams memory params = IElection.ElectionParams({
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

        votsEngine.createElection(params);
        // startTimestamp,
        // endTimestamp,
        // ELECTION_NAME,
        // candidatesList,
        // votersList,
        // pollingUnitAddresses,
        // pollingOfficerAddresses,
        // electionCategories

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Try to get results before election ends
        vm.expectRevert(
            abi.encodeWithSelector(
                Election.Election__InvalidElectionState.selector,
                IElection.ElectionState.ENDED,
                IElection.ElectionState.OPENED
            )
        );
        votsEngine.getAllCandidates(tokenId);
    }

    // ====================================================================
    // State Management Tests
    // ====================================================================

    function testUpdateElectionState() public {
        // Create election
        // vm.prank(creator);
        // votsEngine.createElection(
        //     startTimestamp,
        //     endTimestamp,
        //     ELECTION_NAME,
        //     candidatesList,
        //     votersList,
        //     pollingUnitAddresses,
        //     pollingOfficerAddresses,
        //     electionCategories
        // );
        _createElectionWithDefaultValues();

        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);

        // Initially OPENED

        VotsEngine.ElectionInfo memory initElectionInfo = votsEngine.getElectionInfo(tokenId);
        assertEq(uint256(initElectionInfo.state), uint256(IElection.ElectionState.OPENED));

        // Move to STARTED
        vm.warp(startTimestamp + 1);
        votsEngine.updateElectionState(tokenId);

        VotsEngine.ElectionInfo memory midElectionInfo = votsEngine.getElectionInfo(tokenId);
        assertEq(uint256(midElectionInfo.state), uint256(IElection.ElectionState.STARTED));

        // Move to ENDED
        vm.warp(endTimestamp + 1);
        votsEngine.updateElectionState(tokenId);
        VotsEngine.ElectionInfo memory endElectionInfo = votsEngine.getElectionInfo(tokenId);
        assertEq(uint256(endElectionInfo.state), uint256(IElection.ElectionState.ENDED));
    }

    // ====================================================================
    // Integration Test - Full Election Flow
    // ====================================================================

    function testFullElectionFlow() public {
        // 1. Create election
        // vm.prank(creator);
        // votsEngine.createElection(
        //     startTimestamp,
        //     endTimestamp,
        //     ELECTION_NAME,
        //     candidatesList,
        //     votersList,
        //     pollingUnitAddresses,
        //     pollingOfficerAddresses,
        //     electionCategories
        // );

        _createElectionWithDefaultValues();
        uint256 tokenId = votsEngine.getElectionTokenId(ELECTION_NAME);
        IElection selectedElection = IElection(votsEngine.getElectionAddress(tokenId));
        // 2. Verify initial state
        assertEq(selectedElection.getRegisteredVotersCount(), votersList.length);
        assertEq(selectedElection.getRegisteredCandidatesCount(), candidatesList.length);
        assertEq(selectedElection.getAccreditedVotersCount(), 0);
        assertEq(selectedElection.getVotedVotersCount(), 0);

        // 3. Start election
        vm.warp(startTimestamp + 1);

        // 4. Accredite all voters
        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterOne.matricNo, tokenId);

        vm.prank(pollingOfficer2);
        votsEngine.accrediteVoter(voterTwo.matricNo, tokenId);

        vm.prank(pollingOfficer1);
        votsEngine.accrediteVoter(voterThree.matricNo, tokenId);
        vm.prank(pollingOfficer2);
        votsEngine.accrediteVoter(voterFour.matricNo, tokenId);

        assertEq(selectedElection.getAccreditedVotersCount(), 4);

        // 5. Cast votes
        IElection.CandidateInfoDTO[] memory votes = new IElection.CandidateInfoDTO[](2);

        votes[0] = candidateOne;
        votes[1] = candidateThree;

        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterOne.matricNo, voterOne.name, votes, tokenId);

        vm.prank(pollingUnit2);
        votsEngine.voteCandidates(voterTwo.matricNo, voterTwo.name, votes, tokenId);

        votes[0] = candidateTwo;
        votes[1] = candidateFour;

        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterThree.matricNo, voterThree.name, votes, tokenId);
        votes[0] = candidateOne;
        votes[1] = candidateFour;

        vm.prank(pollingUnit1);
        votsEngine.voteCandidates(voterFour.matricNo, voterFour.name, votes, tokenId);

        assertEq(selectedElection.getVotedVotersCount(), 4);

        // 6. End election and check results
        vm.warp(endTimestamp + 1);

        Election.ElectionWinner[][] memory winners = votsEngine.getEachCategoryWinner(tokenId);

        // President: John Doe should win with 2 votes
        assertEq(winners[0].length, 1);
        assertEq(winners[0][0].matricNo, candidateOne.matricNo);
        assertEq(winners[0][0].electionCandidate.votes, 3);

        // Vice President: Should be a tie with 1 vote each
        assertEq(winners[1].length, 2);
    }
}
