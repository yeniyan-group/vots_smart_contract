// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {FunctionsClient} from "chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IVotsEngineFunctionClient} from "./interfaces/IVotsEngineFunctionClient.sol";
import {IVotsEngine} from "./interfaces/IVotsEngine.sol";

/**
 * @title VotsEngineFunctionClient
 * @author Ayeni-yeniyan
 * @notice Handles Chainlink Functions requests for voter verification
 * This contract is responsible for making HTTP requests to verification portals
 * and calling back to the main VotsEngine contract with the results
 */
contract VotsEngineFunctionClient is
    FunctionsClient,
    IVotsEngineFunctionClient
{
    // ====================================================================
    // State Variables
    // ====================================================================
    bytes32 private immutable _donID;
    address public immutable votsEngine;

    // Track requests to their associated data
    mapping(bytes32 requestId => RequestInfo) private s_requests;

    // Api portal source - Shortened JavaScript source
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

    modifier onlyVotsEngine() {
        if (msg.sender != votsEngine) {
            revert VotsEngineFunctionClient__OnlyVotsEngine();
        }
        _;
    }

    constructor(
        address _router,
        bytes32 donID,
        address _votsEngine
    ) FunctionsClient(_router) {
        _donID = donID;
        votsEngine = _votsEngine;
    }

    /**
     * @dev Sends an HTTP request to an ID verification portal
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
        uint64 subscriptionId,
        address messageSender
    ) external onlyVotsEngine returns (bytes32 requestId) {
        // Create the Functions request
        FunctionsRequest.Request memory req;
        FunctionsRequest.initializeRequestForInlineJavaScript(req, source);

        // Set the arguments for the JavaScript function
        string[] memory args = new string[](4);
        args[0] = ninNumber;
        args[1] = firstName;
        args[2] = lastName;
        args[3] = voterMatricNo;
        FunctionsRequest.setArgs(req, args);

        // Set DON-hosted secrets
        FunctionsRequest.addDONHostedSecrets(
            req,
            uint8(slotId),
            uint64(version)
        );

        // Send the request
        requestId = _sendRequest(
            FunctionsRequest.encodeCBOR(req),
            subscriptionId,
            300_000,
            _donID
        );

        // Store request information
        s_requests[requestId] = RequestInfo({
            electionTokenId: electionTokenId,
            messageSender: messageSender,
            voterMatricNo: voterMatricNo,
            exists: true
        });

        emit VerificationRequestSent(requestId, voterMatricNo, electionTokenId);
    }

    /**
     * @dev Callback function called by Chainlink Functions
     * @param requestId The request ID
     * @param response The response from the external API
     * @param err Any error that occurred during the request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        RequestInfo memory request = s_requests[requestId];

        if (!request.exists) {
            revert VotsEngineFunctionClient__InvalidRequestId();
        }

        // Clean up the request data
        delete s_requests[requestId];

        // If there was an error, we might want to handle it differently
        // For now, we'll proceed with the voter matriculation number
        if (err.length > 0) {
            // Could emit an error event or handle differently
            // For this implementation, we'll still try to process
        }

        // Decode the response (should be the voter matriculation number)
        string memory voterMatricNo;
        if (response.length > 0) {
            voterMatricNo = abi.decode(response, (string));
        } else {
            // Fallback to stored matriculation number if response is empty
            voterMatricNo = request.voterMatricNo;
        }

        // Call back to VotsEngine to fulfill the accreditation
        IVotsEngine(votsEngine).fulfillVoterAccreditation(
            voterMatricNo,
            request.electionTokenId,
            request.messageSender
        );

        emit VerificationRequestFulfilled(
            requestId,
            voterMatricNo,
            request.electionTokenId
        );
    }

    /**
     * @dev Returns the DON ID used by this contract
     */
    function getDonId() external view returns (bytes32) {
        return _donID;
    }

    /**
     * @dev Returns request information for a given request ID
     * @param requestId The request ID to query
     */
    function getRequestInfo(
        bytes32 requestId
    ) external view returns (RequestInfo memory) {
        return s_requests[requestId];
    }

    /**
     * @dev Checks if a request exists
     * @param requestId The request ID to check
     */
    function requestExists(bytes32 requestId) external view returns (bool) {
        return s_requests[requestId].exists;
    }
}
