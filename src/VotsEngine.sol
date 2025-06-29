// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IElection} from "./interfaces/IElection.sol";
import {CreateElection} from "./CreateElection.sol";
import {FunctionsClient} from "chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {VotsEngineLib} from "./libraries/VotsEngineLib.sol";
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
contract VotsEngine is FunctionsClient {
    using VotsEngineLib for mapping(uint256 => address);
    // ====================================================================
    // Errors
    // ====================================================================
    error VotsEngine__DuplicateElectionName();
    error VotsEngine__ElectionNotFound();
    error VotsEngine__ElectionNameCannotBeEmpty();

    // ====================================================================
    // Events
    // ====================================================================
    event ElectionContractedCreated(
        uint256 newElectionTokenId,
        string electionName
    );

    bytes32 private immutable _donID;
    address private electionCreator;
    uint256 private tokenIdCount;
    mapping(uint256 tokenId => address electionAddress) s_tokenToAddress;
    mapping(string electionName => uint256 tokenId) electionNameToTokenId;

    // This is used to track the election where the voters accredited when the function is called
    mapping(string voterMatricNo => RequestInfo electionRequest) s_votersToElectionId;

    modifier validElection(uint256 electionTokenId) {
        if (s_tokenToAddress[electionTokenId] == address(0))
            revert VotsEngine__ElectionNotFound();
        _;
    }

    struct RequestInfo {
        uint256 electionId;
        address messageSender;
    }

    struct ElectionSummary {
        uint256 electionId;
        string electionName;
        string electionDescription;
        IElection.ElectionState state;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 registeredVotersCount;
    }

    // Api portal source
    // Shortened JavaScript source
    string private constant source =
        "const n=args[0]??'63184876213',f=args[1]??'Bunch',l=args[2]??'Dillon',v=args[3],"
        "c=secrets.VERIFYME_CLIENT_ID,k=secrets.VERIFYME_TESTKEY;"
        "if(!k||!c)throw Error('Missing secrets');"
        "const a=await Functions.makeHttpRequest({method:'POST',url:'https://api.qoreid.com/token',"
        "data:{secret:k,clientId:c},headers:{'accept':'text/plain','content-type':'application/json'}});"
        "if(a.error)throw Error('Auth failed');"
        "const r=await Functions.makeHttpRequest({method:'POST',"
        "url:`https://api.qoreid.com/v1/ng/identities/nin/${n}`,"
        "headers:{'accept':'application/json','content-type':'application/json',"
        "authorization:`Bearer ${a.data.accessToken}`},data:{firstname:f,lastname:l}});"
        "if(r.error)throw Error('Request failed');"
        "return Functions.encodeString(v);";

    struct ElectionInfo {
        uint256 electionId;
        address createdBy;
        string electionName;
        string electionDescription;
        IElection.ElectionState state;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 registeredVotersCount;
        uint256 accreditedVotersCount;
        uint256 votedVotersCount;
        string[] electionCategories;
        address[] pollingOfficers;
        address[] pollingUnits;
        IElection.CandidateInfoDTO[] candidatesList;
    }
    constructor(address _router, bytes32 donID) FunctionsClient(_router) {
        _donID = donID;
    }

    function createElection(IElection.ElectionParams calldata params) external {
        // Check that electionName is not duplicate
        uint256 tokenId = electionNameToTokenId[params.electionName];
        if (bytes(params.electionName).length == 0) {
            revert VotsEngine__ElectionNameCannotBeEmpty();
        }
        if (tokenId > 0) {
            revert VotsEngine__DuplicateElectionName();
        }
        // Generate tokenId for election
        uint256 newElectionTokenId = ++tokenIdCount;
        if (electionCreator == address(0)) {
            electionCreator = address(new CreateElection());
        }

        address electionAddress = CreateElection(electionCreator)
            .createElection({
                createdBy: msg.sender,
                electionUniqueTokenId: newElectionTokenId,
                params: params
            });
        // Store election address
        s_tokenToAddress[newElectionTokenId] = electionAddress;
        // Store election name
        electionNameToTokenId[params.electionName] = newElectionTokenId;
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

    function fulfillRequest(
        bytes32 /*requestId*/,
        bytes memory response,
        bytes memory /*err*/
    ) internal override {
        string memory voterMatricNo = abi.decode(response, (string));
        RequestInfo memory request = s_votersToElectionId[voterMatricNo];
        IElection(s_tokenToAddress[request.electionId]).accrediteVoter(
            voterMatricNo,
            request.messageSender
        );
    }

    /// Sends an HTTP request to an id verification portal. Note that this is using test environment and as such would only verify on valid test variables from the verification portal
    /// return requestId The ID of the request

    function sendVerificationRequestForElection(
        string calldata ninNumber,
        string calldata firstName,
        string calldata lastName,
        string calldata voterMatricNo,
        uint256 slotId,
        uint256 version,
        uint256 electionTokenId,
        uint64 subscriptionId
    ) external validElection(electionTokenId) {
        s_votersToElectionId[voterMatricNo] = RequestInfo(
            electionTokenId,
            msg.sender
        );

        FunctionsRequest.Request memory req;
        FunctionsRequest.initializeRequestForInlineJavaScript(req, source);
        // Set the args

        // Set the arguments for the JavaScript function
        string[] memory args = new string[](4);
        args[0] = ninNumber;
        args[1] = firstName;
        args[2] = lastName;
        args[3] = voterMatricNo;
        FunctionsRequest.setArgs(req, args);

        // Set DON-hosted secrets (from your upload)
        FunctionsRequest.addDONHostedSecrets(
            req,
            uint8(slotId),
            uint64(version)
        );

        _sendRequest(
            FunctionsRequest.encodeCBOR(req),
            subscriptionId,
            300_000,
            _donID
        );
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
        // return
        //     IElection(s_tokenToAddress[electionTokenId]).validateVoterForVoting(
        //         voterName,
        //         voterMatricNo,
        //         msg.sender
        //     );

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

        // return
        //     IElection(s_tokenToAddress[electionTokenId])
        //         .validateAddressAsPollingUnit(msg.sender);
    }

    function validateAddressAsPollingOfficer(
        uint256 electionTokenId
    ) external validElection(electionTokenId) returns (bool) {
        return
            s_tokenToAddress.validateAddressAsPollingOfficer(
                electionTokenId,
                msg.sender
            );

        // return
        //     IElection(s_tokenToAddress[electionTokenId])
        //         .validateAddressAsPollingOfficer(msg.sender);
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

    // /**
    //  * @dev Checks if an election exists by name
    //  * @param electionName The name of the election
    //  * @return bool True if election exists
    //  */
    // function electionExists(
    //     string calldata electionName
    // ) public view returns (bool) {
    //     return electionNameToTokenId[electionName] > 0;
    // }

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
        // return
        //     VotsEngineLib.createElectionInfo(
        //         IElection(s_tokenToAddress[electionTokenId])
        //     );

        IElection election = s_tokenToAddress.validateAndGetElection(
            electionTokenId
        );
        return VotsEngineLib.createElectionInfo(election);
    }

    // /**
    //  * @dev Returns the count of registered voters for an election
    //  * @param electionTokenId The token ID of the election
    //  */
    // function getRegisteredVotersCount(
    //     uint256 electionTokenId
    // ) public view validElection(electionTokenId) returns (uint256) {
    //     IElection election = IElection(s_tokenToAddress[electionTokenId]);
    //     return election.getRegisteredVotersCount();
    // }

    // /**
    //  * @dev Returns the count of accredited voters for an election
    //  * @param electionTokenId The token ID of the election
    //  */
    // function getAccreditedVotersCount(
    //     uint256 electionTokenId
    // ) public view validElection(electionTokenId) returns (uint256) {
    //     IElection election = IElection(s_tokenToAddress[electionTokenId]);
    //     return election.getAccreditedVotersCount();
    // }

    // /**
    //  * @dev Returns the count of voters who have voted for an election
    //  * @param electionTokenId The token ID of the election
    //  */
    // function getVotedVotersCount(
    //     uint256 electionTokenId
    // ) public view validElection(electionTokenId) returns (uint256) {
    //     IElection election = IElection(s_tokenToAddress[electionTokenId]);
    //     return election.getVotedVotersCount();
    // }

    // /**
    //  * @dev Returns the count of registered candidates for an election
    //  * @param electionTokenId The token ID of the election
    //  */
    // function getRegisteredCandidatesCount(
    //     uint256 electionTokenId
    // ) public view validElection(electionTokenId) returns (uint256) {
    //     IElection election = IElection(s_tokenToAddress[electionTokenId]);
    //     return election.getRegisteredCandidatesCount();
    // }

    // /**
    //  * @dev Returns the count of polling officers for an election
    //  * @param electionTokenId The token ID of the election
    //  */
    // function getPollingOfficerCount(
    //     uint256 electionTokenId
    // ) public view validElection(electionTokenId) returns (uint256) {
    //     IElection election = IElection(s_tokenToAddress[electionTokenId]);
    //     return election.getPollingOfficerCount();
    // }

    // /**
    //  * @dev Returns the count of polling units for an election
    //  * @param electionTokenId The token ID of the election
    //  */
    // function getPollingUnitCount(
    //     uint256 electionTokenId
    // ) public view validElection(electionTokenId) returns (uint256) {
    //     IElection election = IElection(s_tokenToAddress[electionTokenId]);
    //     return election.getPollingUnitCount();
    // }

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
        // IElection election = IElection(s_tokenToAddress[electionTokenId]);
        // return (
        //     election.getRegisteredVotersCount(),
        //     election.getAccreditedVotersCount(),
        //     election.getVotedVotersCount(),
        //     election.getRegisteredCandidatesCount(),
        //     election.getPollingOfficerCount(),
        //     election.getPollingUnitCount()
        // );

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
        // uint256 totalElections = tokenIdCount;
        // electionsSummaryList = new ElectionSummary[](totalElections);

        // for (uint256 i = 1; i <= totalElections; i++) {
        //     if (s_tokenToAddress[i] != address(0)) {
        //         IElection election = IElection(s_tokenToAddress[i]);
        //         electionsSummaryList[i - 1] = ElectionSummary({
        //             electionId: election.getElectionUniqueTokenId(),
        //             electionName: election.getElectionName(),
        //             electionDescription: election.getElectionDescription(),
        //             state: election.getElectionState(),
        //             startTimestamp: election.getStartTimeStamp(),
        //             endTimestamp: election.getEndTimeStamp(),
        //             registeredVotersCount: election.getRegisteredVotersCount()
        //         });
        //     }
        // }
    }
}
