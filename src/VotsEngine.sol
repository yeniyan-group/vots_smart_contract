// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IElection} from "./interfaces/IElection.sol";
import {ICreateElection} from "./interfaces/ICreateElection.sol";
import {CreateElection} from "./CreateElection.sol";
import {VotsEngineLib} from "./libraries/VotsEngineLib.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVotsEngineFunctionClient} from "./interfaces/IVotsEngineFunctionClient.sol";
import {IVotsEngine} from "./interfaces/IVotsEngine.sol";
import {IVotsElectionNft} from "./interfaces/IVotsElectionNft.sol";

/**
 * @title VotsEngine
 * @author Ayeni-yeniyan
 * @notice This is the core of the voting system.
 * This contract creates the election contract and tokenises the created contract address.
 * Only this contract has access to interact with the election contracts.
 * When an election is created, it gets a unique election id which identifies it.
 * An election contract is created with a unique name that is stored in memory and can be used to get the election address.
 * Each election is tokenised and the address is stored on chain to enable future access and reference.
 */
contract VotsEngine is IVotsEngine, Ownable {
    using VotsEngineLib for mapping(uint256 => address);

    // ====================================================================
    // State Variables
    // ====================================================================
    address private immutable electionCreator;
    address private immutable nftAddress;
    address public functionClient;
    uint256 private tokenIdCount;

    mapping(uint256 tokenId => address electionAddress) s_tokenToAddress;
    mapping(string electionName => uint256 tokenId) electionNameToTokenId;

    modifier validElection(uint256 electionTokenId) {
        if (s_tokenToAddress[electionTokenId] == address(0)) {
            revert IVotsEngine.VotsEngine__ElectionNotFound();
        }
        _;
    }

    modifier onlyFunctionClient() {
        if (msg.sender != functionClient) {
            revert IVotsEngine.VotsEngine__OnlyFunctionClient();
        }
        _;
    }

    // ====================================================================
    // Modifiers
    // ====================================================================

    constructor(
        address _electionCreator,
        address _nftAddress
    ) Ownable(msg.sender) {
        electionCreator = _electionCreator;
        nftAddress = _nftAddress;
    }

    /**
     * @dev Sets the function client address (only owner)
     * @param _functionClient Address of the VotsEngineFunctionClient contract
     */
    function setFunctionClient(address _functionClient) external onlyOwner {
        address oldClient = functionClient;
        functionClient = _functionClient;
        emit FunctionClientUpdated(oldClient, _functionClient);
    }

    function createElection(IElection.ElectionParams calldata params) external {
        // Check that electionName is not duplicate
        uint256 tokenId = electionNameToTokenId[params.electionName];
        if (bytes(params.electionName).length == 0) {
            revert IVotsEngine.VotsEngine__ElectionNameCannotBeEmpty();
        }
        if (tokenId > 0) {
            revert IVotsEngine.VotsEngine__DuplicateElectionName();
        }
        // Generate tokenId for election
        uint256 newElectionTokenId = ++tokenIdCount;
        address electionAddress = ICreateElection(electionCreator)
            .createElection({
                createdBy: msg.sender,
                electionUniqueTokenId: newElectionTokenId,
                params: params
            });
        // Store election address
        s_tokenToAddress[newElectionTokenId] = electionAddress;
        // Store election name
        electionNameToTokenId[params.electionName] = newElectionTokenId;

        // mint nft to user
        IVotsElectionNft(nftAddress).mintElectionNft(
            msg.sender,
            newElectionTokenId,
            params.electionName,
            params.description,
            params.startTimeStamp,
            params.endTimeStamp
        );
        // Emit creation event
        emit ElectionContractedCreated(newElectionTokenId, params.electionName);
    }

    function accrediteVoter(
        string calldata voterMatricNo,
        uint256 electionTokenId
    ) external validElection(electionTokenId) {
        // Call accredite function
        IElection(s_tokenToAddress[electionTokenId]).accrediteVoter(
            voterMatricNo,
            msg.sender
        );
    }

    /**
     * @dev Called by VotsEngineFunctionClient to fulfill voter accreditation
     * @param voterMatricNo The voter's matriculation number
     * @param electionTokenId The election token ID
     * @param messageSender The original message sender who initiated the request
     */
    function fulfillVoterAccreditation(
        string calldata voterMatricNo,
        uint256 electionTokenId,
        address messageSender
    ) external onlyFunctionClient validElection(electionTokenId) {
        IElection(s_tokenToAddress[electionTokenId]).accrediteVoter(
            voterMatricNo,
            messageSender
        );
    }

    /**
     * @dev Sends a verification request through the function client
     * @param ninNumber National identification number
     * @param firstName First name of the voter
     * @param lastName Last name of the voter
     * @param voterMatricNo Voter's matriculation number
     * @param slotId DON-hosted secrets slot ID
     * @param version DON-hosted secrets version
     * @param electionTokenId Token ID of the election
     * @param subscriptionId Chainlink Functions subscription ID
     * @return requestId The ID of the request
     */
    function sendVerificationRequestForElection(
        string calldata ninNumber,
        string calldata firstName,
        string calldata lastName,
        string calldata voterMatricNo,
        uint256 slotId,
        uint256 version,
        uint256 electionTokenId,
        uint64 subscriptionId
    ) external validElection(electionTokenId) returns (bytes32 requestId) {
        if (functionClient == address(0)) {
            revert IVotsEngine.VotsEngine__FunctionClientNotSet();
        }

        requestId = IVotsEngineFunctionClient(functionClient)
            .sendVerificationRequestForElection(
                ninNumber,
                firstName,
                lastName,
                voterMatricNo,
                slotId,
                version,
                electionTokenId,
                subscriptionId,
                msg.sender
            );

        emit VerificationRequestSent(requestId, voterMatricNo, electionTokenId);
    }

    function voteCandidates(
        string calldata voterMatricNo,
        string calldata voterName,
        IElection.CandidateInfoDTO[] calldata candidatesList,
        uint256 electionTokenId
    ) external validElection(electionTokenId) {
        // Call vote function
        IElection(s_tokenToAddress[electionTokenId]).voteCandidates(
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
    ) external validElection(electionTokenId) returns (bool) {
        return
            s_tokenToAddress.validateVoterForVoting(
                voterMatricNo,
                voterName,
                electionTokenId,
                msg.sender
            );
    }

    function validateAddressAsPollingUnit(
        uint256 electionTokenId
    ) external validElection(electionTokenId) returns (bool) {
        return
            s_tokenToAddress.validateAddressAsPollingUnit(
                electionTokenId,
                msg.sender
            );
    }

    function validateAddressAsPollingOfficer(
        uint256 electionTokenId
    ) external validElection(electionTokenId) returns (bool) {
        return
            s_tokenToAddress.validateAddressAsPollingOfficer(
                electionTokenId,
                msg.sender
            );
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
        return s_tokenToAddress[electionTokenId];
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
     * @dev Checks if an election exists by token ID
     * @param electionTokenId The token ID of the election
     * @return bool True if election exists
     */
    function electionExistsByTokenId(
        uint256 electionTokenId
    ) public view returns (bool) {
        return s_tokenToAddress[electionTokenId] != address(0);
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
    ) public view validElection(electionTokenId) returns (ElectionInfo memory) {
        IElection election = s_tokenToAddress.validateAndGetElection(
            electionTokenId
        );
        return VotsEngineLib.createElectionInfo(election);
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
        return s_tokenToAddress.getElectionStats(electionTokenId);
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
        returns (IElection.ElectionVoter[] memory)
    {
        return IElection(s_tokenToAddress[electionTokenId]).getAllVoters();
    }

    /**
     * @dev Returns all accredited voters for an election
     * @param electionTokenId The token ID of the election
     */
    function getAllAccreditedVoters(
        uint256 electionTokenId
    )
        external
        view
        validElection(electionTokenId)
        returns (IElection.ElectionVoter[] memory)
    {
        return
            IElection(s_tokenToAddress[electionTokenId])
                .getAllAccreditedVoters();
    }

    /**
     * @dev Returns all voters who have voted for an election
     * @param electionTokenId The token ID of the election
     */
    function getAllVotedVoters(
        uint256 electionTokenId
    )
        external
        view
        validElection(electionTokenId)
        returns (IElection.ElectionVoter[] memory)
    {
        return IElection(s_tokenToAddress[electionTokenId]).getAllVotedVoters();
    }

    /**
     * @dev Returns all candidates for an election (as DTOs)
     * @param electionTokenId The token ID of the election
     */
    function getAllCandidatesInDto(
        uint256 electionTokenId
    )
        external
        view
        validElection(electionTokenId)
        returns (IElection.CandidateInfoDTO[] memory)
    {
        return
            IElection(s_tokenToAddress[electionTokenId])
                .getAllCandidatesInDto();
    }

    /**
     * @dev Returns all candidates with vote counts (only after election ends)
     * @param electionTokenId The token ID of the election
     */
    function getAllCandidates(
        uint256 electionTokenId
    )
        external
        view
        validElection(electionTokenId)
        returns (IElection.ElectionCandidate[] memory)
    {
        IElection election = IElection(s_tokenToAddress[electionTokenId]);
        return election.getAllCandidates();
    }

    /**
     * @dev Returns winners for each category (handles ties)
     * @param electionTokenId The token ID of the election
     */
    function getEachCategoryWinner(
        uint256 electionTokenId
    )
        external
        view
        validElection(electionTokenId)
        returns (IElection.ElectionWinner[][] memory)
    {
        IElection election = IElection(s_tokenToAddress[electionTokenId]);
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
    ) external validElection(electionTokenId) {
        IElection(s_tokenToAddress[electionTokenId]).updateElectionState();
    }

    /**
     * @dev Returns a summary of all elections (basic info only)
     * @return electionsSummaryList Array of the election summary
     */
    function getAllElectionsSummary()
        external
        view
        returns (ElectionSummary[] memory electionsSummaryList)
    {
        uint256 totalElections = tokenIdCount;
        electionsSummaryList = new ElectionSummary[](totalElections);

        for (uint256 i = 1; i <= totalElections; i++) {
            address electionAddr = s_tokenToAddress[i];
            if (electionAddr != address(0)) {
                IElection election = IElection(electionAddr);
                electionsSummaryList[i - 1] = VotsEngineLib
                    .createElectionSummary(election);
            }
        }
    }

    /**
     * @dev Returns the current owner of the contract
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the current function client address
     */
    function getFunctionClient() external view returns (address) {
        return functionClient;
    }

    /**
     * @dev Returns the current function client address
     */
    function getNFTAddres() external view returns (address) {
        return nftAddress;
    }
}
