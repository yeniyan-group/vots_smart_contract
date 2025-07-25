// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19 ^0.8.20 ^0.8.21 ^0.8.24 ^0.8.4;

// lib/chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsClient.sol

/// @title Chainlink Functions client interface.
interface IFunctionsClient {
  /// @notice Chainlink Functions response handler called by the Functions Router
  /// during fullilment from the designated transmitter node in an OCR round.
  /// @param requestId The requestId returned by FunctionsClient.sendRequest().
  /// @param response Aggregated response from the request's source code.
  /// @param err Aggregated error either from the request's source code or from the execution pipeline.
  /// @dev Either response or error parameter will be set, but never both.
  function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external;
}

// lib/chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsResponse.sol

/// @title Library of types that are used for fulfillment of a Functions request
library FunctionsResponse {
  // Used to send request information from the Router to the Coordinator
  struct RequestMeta {
    bytes data; // ══════════════════╸ CBOR encoded Chainlink Functions request data, use FunctionsRequest library to encode a request
    bytes32 flags; // ═══════════════╸ Per-subscription flags
    address requestingContract; // ══╗ The client contract that is sending the request
    uint96 availableBalance; // ═════╝ Common LINK balance of the subscription that is controlled by the Router to be used for all consumer requests.
    uint72 adminFee; // ═════════════╗ Flat fee (in Juels of LINK) that will be paid to the Router Owner for operation of the network
    uint64 subscriptionId; //        ║ Identifier of the billing subscription that will be charged for the request
    uint64 initiatedRequests; //     ║ The number of requests that have been started
    uint32 callbackGasLimit; //      ║ The amount of gas that the callback to the consuming contract will be given
    uint16 dataVersion; // ══════════╝ The version of the structure of the CBOR encoded request data
    uint64 completedRequests; // ════╗ The number of requests that have successfully completed or timed out
    address subscriptionOwner; // ═══╝ The owner of the billing subscription
  }

  enum FulfillResult {
    FULFILLED, // 0
    USER_CALLBACK_ERROR, // 1
    INVALID_REQUEST_ID, // 2
    COST_EXCEEDS_COMMITMENT, // 3
    INSUFFICIENT_GAS_PROVIDED, // 4
    SUBSCRIPTION_BALANCE_INVARIANT_VIOLATION, // 5
    INVALID_COMMITMENT // 6
  }

  struct Commitment {
    bytes32 requestId; // ═════════════════╸ A unique identifier for a Chainlink Functions request
    address coordinator; // ═══════════════╗ The Coordinator contract that manages the DON that is servicing a request
    uint96 estimatedTotalCostJuels; // ════╝ The maximum cost in Juels (1e18) of LINK that will be charged to fulfill a request
    address client; // ════════════════════╗ The client contract that sent the request
    uint64 subscriptionId; //              ║ Identifier of the billing subscription that will be charged for the request
    uint32 callbackGasLimit; // ═══════════╝ The amount of gas that the callback to the consuming contract will be given
    uint72 adminFee; // ═══════════════════╗ Flat fee (in Juels of LINK) that will be paid to the Router Owner for operation of the network
    uint72 donFee; //                      ║ Fee (in Juels of LINK) that will be split between Node Operators for servicing a request
    uint40 gasOverheadBeforeCallback; //   ║ Represents the average gas execution cost before the fulfillment callback.
    uint40 gasOverheadAfterCallback; //    ║ Represents the average gas execution cost after the fulfillment callback.
    uint32 timeoutTimestamp; // ═══════════╝ The timestamp at which a request will be eligible to be timed out
  }
}

// lib/chainlink/contracts/src/v0.8/vendor/@ensdomains/buffer/v0.1.0/Buffer.sol

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for appending to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            let fpm := add(32, add(ptr, capacity))
            if lt(fpm, ptr) {
                revert(0, 0)
            }
            mstore(0x40, fpm)
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Appends len bytes of a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        uint off = buf.buf.length;
        uint newCapacity = off + len;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint dest;
        uint src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(newCapacity, buflen) {
                mstore(bufptr, newCapacity)
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return append(buf, data, data.length);
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        uint off = buf.buf.length;
        uint offPlusOne = off + 1;
        if (off >= buf.capacity) {
            resize(buf, offPlusOne * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if gt(offPlusOne, mload(bufptr)) {
                mstore(bufptr, offPlusOne)
            }
        }

        return buf;
    }

    /**
    * @dev Appends len bytes of bytes32 to a buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes32 data, uint len) private pure returns(buffer memory) {
        uint off = buf.buf.length;
        uint newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        unchecked {
            uint mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + newCapacity
                let dest := add(bufptr, newCapacity)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(newCapacity, mload(bufptr)) {
                    mstore(bufptr, newCapacity)
                }
            }
        }
        return buf;
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return append(buf, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return append(buf, data, 32);
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        uint off = buf.buf.length;
        uint newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + newCapacity
            let dest := add(bufptr, newCapacity)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(newCapacity, mload(bufptr)) {
                mstore(bufptr, newCapacity)
            }
        }
        return buf;
    }
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// src/interfaces/IElection.sol

/**
 * @title IElection
 * @dev Interface for the Election contract containing only functions called by VotsEngine
 * @author Ayeni-yeniyan
 * @notice Interface for individual election contracts managed by VotsEngine
 */
interface IElection {
    // ====================================================================
    // Structs (Referenced by VotsEngine)
    // ====================================================================

    enum ElectionState {
        OPENED,
        STARTED,
        ENDED
    }

    enum CandidateState {
        UNKNOWN,
        REGISTERED
    }

    /**
     * @dev Voters state Enum
     */
    enum VoterState {
        UNKNOWN,
        REGISTERED,
        ACCREDITED,
        VOTED
    }

    struct ElectionParams {
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        string electionName;
        string description;
        CandidateInfoDTO[] candidatesList;
        VoterInfoDTO[] votersList;
        address[] pollingUnitAddresses;
        address[] pollingOfficerAddresses;
        string[] electionCategories;
    }

    /**
     * @dev This is for storing the unregistered candidates only
     */
    struct CandidateInfoDTO {
        string name;
        string matricNo;
        string category;
        uint256 voteFor;
        uint256 voteAgainst;
    }

    /**
     * @dev This structure is for registering voters only
     */
    struct VoterInfoDTO {
        string name;
        string matricNo;
    }

    /**
     * @dev Defines the structure of our voter
     */
    struct ElectionVoter {
        string name;
        VoterState voterState;
    }

    /**
     * @dev Structure for election candidates
     */
    struct ElectionCandidate {
        string name;
        uint256 votes;
        uint256 votesAgainst;
        CandidateState state;
    }

    /**
     * @dev Winner of each election category
     */
    struct ElectionWinner {
        string matricNo;
        ElectionCandidate electionCandidate;
        string category;
    }

    // ====================================================================
    // Voter Management Functions
    // ====================================================================

    /**
     * @dev Accredits a voter for this election
     * @param voterMatricNo The voter's matriculation number
     * @param accreditedBy Address that accredited the voter
     */
    function accrediteVoter(
        string calldata voterMatricNo,
        address accreditedBy
    ) external;

    /**
     * @dev Validates if a voter can vote in this election
     * @param voterName The voter's name
     * @param voterMatricNo The voter's matriculation number
     * @param votedBy Address attempting to vote
     * @return bool True if voter is valid for voting
     */
    function validateVoterForVoting(
        string memory voterName,
        string memory voterMatricNo,
        address votedBy
    ) external returns (bool);

    /**
     * @dev Processes votes for candidates
     * @param voterMatricNo The voter's matriculation number
     * @param voterName The voter's name
     * @param votedBy Address that cast the vote
     * @param candidatesList List of candidates being voted for
     */
    function voteCandidates(
        string calldata voterMatricNo,
        string calldata voterName,
        address votedBy,
        CandidateInfoDTO[] calldata candidatesList
    ) external;

    // ====================================================================
    // Validation Functions
    // ====================================================================

    /**
     * @dev Validates if an address is a polling unit
     * @param pollingUnit Address to validate
     * @return bool True if address is a polling unit
     */
    function validateAddressAsPollingUnit(
        address pollingUnit
    ) external returns (bool);

    /**
     * @dev Validates if an address is a polling officer
     * @param pollingOfficer Address to validate
     * @return bool True if address is a polling officer
     */
    function validateAddressAsPollingOfficer(
        address pollingOfficer
    ) external returns (bool);

    // ====================================================================
    // Getter Functions - Basic Info
    // ====================================================================

    /**
     * @dev Returns the election's unique token ID
     * @return uint256 The election token ID
     */
    function getElectionUniqueTokenId() external view returns (uint256);

    /**
     * @dev Returns the address that created this election
     * @return address Creator's address
     */
    function getCreatedBy() external view returns (address);

    /**
     * @dev Returns the election name
     * @return string Election name
     */
    function getElectionName() external view returns (string memory);

    /**
     * @dev Returns the election description
     * @return string Election description
     */
    function getElectionDescription() external view returns (string memory);

    /**
     * @dev Returns the current election state
     * @return ElectionState Current state
     */
    function getElectionState() external view returns (ElectionState);

    /**
     * @dev Returns the election start timestamp
     * @return uint256 Start timestamp
     */
    function getStartTimeStamp() external view returns (uint256);

    /**
     * @dev Returns the election end timestamp
     * @return uint256 End timestamp
     */
    function getEndTimeStamp() external view returns (uint256);

    /**
     * @dev Returns the election categories
     * @return string[] Array of categories
     */
    function getElectionCategories() external view returns (string[] memory);

    // ====================================================================
    // Getter Functions - Counts
    // ====================================================================

    /**
     * @dev Returns the count of registered voters
     * @return uint256 Registered voters count
     */
    function getRegisteredVotersCount() external view returns (uint256);

    /**
     * @dev Returns the count of accredited voters
     * @return uint256 Accredited voters count
     */
    function getAccreditedVotersCount() external view returns (uint256);

    /**
     * @dev Returns the count of voters who have voted
     * @return uint256 Voted voters count
     */
    function getVotedVotersCount() external view returns (uint256);

    /**
     * @dev Returns the count of registered candidates
     * @return uint256 Candidates count
     */
    function getRegisteredCandidatesCount() external view returns (uint256);

    /**
     * @dev Returns the count of polling officers
     * @return uint256 Polling officers count
     */
    function getPollingOfficerCount() external view returns (uint256);

    /**
     * @dev Returns the count of polling units
     * @return uint256 Polling units count
     */
    function getPollingUnitCount() external view returns (uint256);

    // ====================================================================
    // Getter Functions - Arrays
    // ====================================================================

    /**
     * @dev Returns all voters in the election
     * @return ElectionVoter[] Array of all voters
     */
    function getAllVoters() external view returns (ElectionVoter[] memory);

    /**
     * @dev Returns all accredited voters
     * @return ElectionVoter[] Array of accredited voters
     */
    function getAllAccreditedVoters()
        external
        view
        returns (ElectionVoter[] memory);

    /**
     * @dev Returns all voters who have voted
     * @return ElectionVoter[] Array of voted voters
     */
    function getAllVotedVoters() external view returns (ElectionVoter[] memory);

    /**
     * @dev Returns all candidates as DTOs (without vote counts)
     * @return CandidateInfoDTO[] Array of candidate DTOs
     */
    function getAllCandidatesInDto()
        external
        view
        returns (CandidateInfoDTO[] memory);

    /**
     * @dev Returns all candidates with vote counts (only after election ends)
     * @return ElectionCandidate[] Array of candidates with vote counts
     */
    function getAllCandidates()
        external
        view
        returns (ElectionCandidate[] memory);

    /**
     * @dev Returns winners for each category (handles ties)
     * @return ElectionWinner[][] Array of winners per category
     */
    function getEachCategoryWinner()
        external
        view
        returns (ElectionWinner[][] memory);

    /**
     * @dev Returns polling officers addresses
     * @return address[] Array of polling officer addresses
     */
    function getPollingOfficersAddresses()
        external
        view
        returns (address[] memory);

    /**
     * @dev Returns polling units addresses
     * @return address[] Array of polling unit addresses
     */
    function getPollingUnitsAddresses()
        external
        view
        returns (address[] memory);

    // ====================================================================
    // State Management
    // ====================================================================

    /**
     * @dev Updates the election state based on current time
     */
    function updateElectionState() external;
}

// src/interfaces/IVotsElectionNft.sol

/**
 * @title IVotsElectionNft
 * @notice Interface for the VotsElectionNft contract
 */
interface IVotsElectionNft {
    /**
     * @dev Struct to store election NFT data
     */
    struct ElectionNftData {
        uint256 electionTokenId;
        string electionName;
        address creator;
        uint256 creationTimestamp;
        string electionDescription;
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * @dev Event emitted when an election NFT is minted
     */
    event ElectionNftMinted(
        uint256 indexed nftTokenId, uint256 indexed electionTokenId, address indexed creator, string electionName
    );

    /**
     * @dev Mints an NFT to the election creator
     */
    function mintElectionNft(
        address creator,
        uint256 electionTokenId,
        string calldata electionName,
        string calldata electionDescription,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256 nftTokenId);

    /**
     * @dev Returns the total number of NFTs minted
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns election data for a given NFT token ID
     */
    function getElectionData(uint256 nftTokenId) external view returns (ElectionNftData memory);

    /**
     * @dev Returns NFT token ID for a given election token ID
     */
    function getNftTokenByElectionId(uint256 electionTokenId) external view returns (uint256);

    /**
     * @dev Returns all NFTs owned by an address
     */
    function getOwnedTokens(address owner) external view returns (uint256[] memory);

    /**
     * @dev Checks if an NFT exists for a given election
     */
    function electionNftExists(uint256 electionTokenId) external view returns (bool);
}

// src/interfaces/IVotsEngineFunctionClient.sol

/**
 * @title IVotsEngineFunctionClient
 * @author Ayeni-yeniyan
 * @notice Interface for the VotsEngineFunctionClient contract
 * Defines the contract that handles Chainlink Functions requests for voter verification
 */
interface IVotsEngineFunctionClient {
    // ====================================================================
    // Errors
    // ====================================================================
    error VotsEngineFunctionClient__OnlyVotsEngine();
    error VotsEngineFunctionClient__InvalidRequestId();

    // ====================================================================
    // Events
    // ====================================================================
    event VerificationRequestSent(bytes32 indexed requestId, string voterMatricNo, uint256 electionTokenId);

    event VerificationRequestFulfilled(bytes32 indexed requestId, string voterMatricNo, uint256 electionTokenId);

    // ====================================================================
    // Structs
    // ====================================================================
    struct RequestInfo {
        uint256 electionTokenId;
        address messageSender;
        string voterMatricNo;
        bool exists;
    }

    // ====================================================================
    // Functions
    // ====================================================================

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
     * @param messageSender Original message sender who initiated the request
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
    ) external returns (bytes32 requestId);

    /**
     * @dev Returns the DON ID used by this contract
     * @return bytes32 The DON ID
     */
    function getDonId() external view returns (bytes32);

    /**
     * @dev Returns the VotsEngine contract address
     * @return address The VotsEngine contract address
     */
    function votsEngine() external view returns (address);

    /**
     * @dev Returns request information for a given request ID
     * @param requestId The request ID to query
     * @return RequestInfo The request information
     */
    function getRequestInfo(bytes32 requestId) external view returns (RequestInfo memory);

    /**
     * @dev Checks if a request exists
     * @param requestId The request ID to check
     * @return bool True if the request exists
     */
    function requestExists(bytes32 requestId) external view returns (bool);
}

// lib/chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol

/// @title Chainlink Functions Router interface.
interface IFunctionsRouter {
  /// @notice The identifier of the route to retrieve the address of the access control contract
  /// The access control contract controls which accounts can manage subscriptions
  /// @return id - bytes32 id that can be passed to the "getContractById" of the Router
  function getAllowListId() external view returns (bytes32);

  /// @notice Set the identifier of the route to retrieve the address of the access control contract
  /// The access control contract controls which accounts can manage subscriptions
  function setAllowListId(bytes32 allowListId) external;

  /// @notice Get the flat fee (in Juels of LINK) that will be paid to the Router owner for operation of the network
  /// @return adminFee
  function getAdminFee() external view returns (uint72 adminFee);

  /// @notice Sends a request using the provided subscriptionId
  /// @param subscriptionId - A unique subscription ID allocated by billing system,
  /// a client can make requests from different contracts referencing the same subscription
  /// @param data - CBOR encoded Chainlink Functions request data, use FunctionsClient API to encode a request
  /// @param dataVersion - Gas limit for the fulfillment callback
  /// @param callbackGasLimit - Gas limit for the fulfillment callback
  /// @param donId - An identifier used to determine which route to send the request along
  /// @return requestId - A unique request identifier
  function sendRequest(
    uint64 subscriptionId,
    bytes calldata data,
    uint16 dataVersion,
    uint32 callbackGasLimit,
    bytes32 donId
  ) external returns (bytes32);

  /// @notice Sends a request to the proposed contracts
  /// @param subscriptionId - A unique subscription ID allocated by billing system,
  /// a client can make requests from different contracts referencing the same subscription
  /// @param data - CBOR encoded Chainlink Functions request data, use FunctionsClient API to encode a request
  /// @param dataVersion - Gas limit for the fulfillment callback
  /// @param callbackGasLimit - Gas limit for the fulfillment callback
  /// @param donId - An identifier used to determine which route to send the request along
  /// @return requestId - A unique request identifier
  function sendRequestToProposed(
    uint64 subscriptionId,
    bytes calldata data,
    uint16 dataVersion,
    uint32 callbackGasLimit,
    bytes32 donId
  ) external returns (bytes32);

  /// @notice Fulfill the request by:
  /// - calling back the data that the Oracle returned to the client contract
  /// - pay the DON for processing the request
  /// @dev Only callable by the Coordinator contract that is saved in the commitment
  /// @param response response data from DON consensus
  /// @param err error from DON consensus
  /// @param juelsPerGas - current rate of juels/gas
  /// @param costWithoutFulfillment - The cost of processing the request (in Juels of LINK ), without fulfillment
  /// @param transmitter - The Node that transmitted the OCR report
  /// @param commitment - The parameters of the request that must be held consistent between request and response time
  /// @return fulfillResult -
  /// @return callbackGasCostJuels -
  function fulfill(
    bytes memory response,
    bytes memory err,
    uint96 juelsPerGas,
    uint96 costWithoutFulfillment,
    address transmitter,
    FunctionsResponse.Commitment memory commitment
  ) external returns (FunctionsResponse.FulfillResult, uint96);

  /// @notice Validate requested gas limit is below the subscription max.
  /// @param subscriptionId subscription ID
  /// @param callbackGasLimit desired callback gas limit
  function isValidCallbackGasLimit(uint64 subscriptionId, uint32 callbackGasLimit) external view;

  /// @notice Get the current contract given an ID
  /// @param id A bytes32 identifier for the route
  /// @return contract The current contract address
  function getContractById(bytes32 id) external view returns (address);

  /// @notice Get the proposed next contract given an ID
  /// @param id A bytes32 identifier for the route
  /// @return contract The current or proposed contract address
  function getProposedContractById(bytes32 id) external view returns (address);

  /// @notice Return the latest proprosal set
  /// @return ids The identifiers of the contracts to update
  /// @return to The addresses of the contracts that will be updated to
  function getProposedContractSet() external view returns (bytes32[] memory, address[] memory);

  /// @notice Proposes one or more updates to the contract routes
  /// @dev Only callable by owner
  function proposeContractsUpdate(bytes32[] memory proposalSetIds, address[] memory proposalSetAddresses) external;

  /// @notice Updates the current contract routes to the proposed contracts
  /// @dev Only callable by owner
  function updateContracts() external;

  /// @dev Puts the system into an emergency stopped state.
  /// @dev Only callable by owner
  function pause() external;

  /// @dev Takes the system out of an emergency stopped state.
  /// @dev Only callable by owner
  function unpause() external;
}

// lib/chainlink/contracts/src/v0.8/vendor/solidity-cborutils/v2.0.0/CBOR.sol

/**
* @dev A library for populating CBOR encoded payload in Solidity.
*
* https://datatracker.ietf.org/doc/html/rfc7049
*
* The library offers various write* and start* methods to encode values of different types.
* The resulted buffer can be obtained with data() method.
* Encoding of primitive types is staightforward, whereas encoding of sequences can result
* in an invalid CBOR if start/write/end flow is violated.
* For the purpose of gas saving, the library does not verify start/write/end flow internally,
* except for nested start/end pairs.
*/

library CBOR {
    using Buffer for Buffer.buffer;

    struct CBORBuffer {
        Buffer.buffer buf;
        uint256 depth;
    }

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    uint8 private constant CBOR_FALSE = 20;
    uint8 private constant CBOR_TRUE = 21;
    uint8 private constant CBOR_NULL = 22;
    uint8 private constant CBOR_UNDEFINED = 23;

    function create(uint256 capacity) internal pure returns(CBORBuffer memory cbor) {
        Buffer.init(cbor.buf, capacity);
        cbor.depth = 0;
        return cbor;
    }

    function data(CBORBuffer memory buf) internal pure returns(bytes memory) {
        require(buf.depth == 0, "Invalid CBOR");
        return buf.buf.buf;
    }

    function writeUInt256(CBORBuffer memory buf, uint256 value) internal pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
        writeBytes(buf, abi.encode(value));
    }

    function writeInt256(CBORBuffer memory buf, int256 value) internal pure {
        if (value < 0) {
            buf.buf.appendUint8(
                uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM)
            );
            writeBytes(buf, abi.encode(uint256(-1 - value)));
        } else {
            writeUInt256(buf, uint256(value));
        }
    }

    function writeUInt64(CBORBuffer memory buf, uint64 value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_INT, value);
    }

    function writeInt64(CBORBuffer memory buf, int64 value) internal pure {
        if(value >= 0) {
            writeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
        } else{
            writeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(-1 - value));
        }
    }

    function writeBytes(CBORBuffer memory buf, bytes memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
        buf.buf.append(value);
    }

    function writeString(CBORBuffer memory buf, string memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        buf.buf.append(bytes(value));
    }

    function writeBool(CBORBuffer memory buf, bool value) internal pure {
        writeContentFree(buf, value ? CBOR_TRUE : CBOR_FALSE);
    }

    function writeNull(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_NULL);
    }

    function writeUndefined(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_UNDEFINED);
    }

    function startArray(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
        buf.depth += 1;
    }

    function startFixedArray(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_ARRAY, length);
    }

    function startMap(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
        buf.depth += 1;
    }

    function startFixedMap(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_MAP, length);
    }

    function endSequence(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
        buf.depth -= 1;
    }

    function writeKVString(CBORBuffer memory buf, string memory key, string memory value) internal pure {
        writeString(buf, key);
        writeString(buf, value);
    }

    function writeKVBytes(CBORBuffer memory buf, string memory key, bytes memory value) internal pure {
        writeString(buf, key);
        writeBytes(buf, value);
    }

    function writeKVUInt256(CBORBuffer memory buf, string memory key, uint256 value) internal pure {
        writeString(buf, key);
        writeUInt256(buf, value);
    }

    function writeKVInt256(CBORBuffer memory buf, string memory key, int256 value) internal pure {
        writeString(buf, key);
        writeInt256(buf, value);
    }

    function writeKVUInt64(CBORBuffer memory buf, string memory key, uint64 value) internal pure {
        writeString(buf, key);
        writeUInt64(buf, value);
    }

    function writeKVInt64(CBORBuffer memory buf, string memory key, int64 value) internal pure {
        writeString(buf, key);
        writeInt64(buf, value);
    }

    function writeKVBool(CBORBuffer memory buf, string memory key, bool value) internal pure {
        writeString(buf, key);
        writeBool(buf, value);
    }

    function writeKVNull(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeNull(buf);
    }

    function writeKVUndefined(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeUndefined(buf);
    }

    function writeKVMap(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startMap(buf);
    }

    function writeKVArray(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startArray(buf);
    }

    function writeFixedNumeric(
        CBORBuffer memory buf,
        uint8 major,
        uint64 value
    ) private pure {
        if (value <= 23) {
            buf.buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.buf.appendUint8(uint8((major << 5) | 24));
            buf.buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 25));
            buf.buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 26));
            buf.buf.appendInt(value, 4);
        } else {
            buf.buf.appendUint8(uint8((major << 5) | 27));
            buf.buf.appendInt(value, 8);
        }
    }

    function writeIndefiniteLengthType(CBORBuffer memory buf, uint8 major)
        private
        pure
    {
        buf.buf.appendUint8(uint8((major << 5) | 31));
    }

    function writeDefiniteLengthType(CBORBuffer memory buf, uint8 major, uint64 length)
        private
        pure
    {
        writeFixedNumeric(buf, major, length);
    }

    function writeContentFree(CBORBuffer memory buf, uint8 value) private pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_CONTENT_FREE << 5) | value));
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// src/interfaces/ICreateElection.sol

interface ICreateElection {
    function createElection(address createdBy, uint256 electionUniqueTokenId, IElection.ElectionParams calldata params)
        external
        returns (address);
}

// src/interfaces/IVotsEngine.sol

/**
 * @title IVotsEngine
 * @author Ayeni-yeniyan
 * @notice Interface for the VotsEngine contract
 * Defines the core voting system functionality
 */
interface IVotsEngine {
    // ====================================================================
    // Errors
    // ====================================================================
    error VotsEngine__DuplicateElectionName();
    error VotsEngine__ElectionNotFound();
    error VotsEngine__ElectionNameCannotBeEmpty();
    error VotsEngine__OnlyFunctionClient();
    error VotsEngine__FunctionClientNotSet();
    error VotsEngine__VaultAddressNotSet();

    // ====================================================================
    // Events
    // ====================================================================
    event ElectionContractedCreated(uint256 newElectionTokenId, string electionName);

    event FunctionClientUpdated(address indexed oldClient, address indexed newClient);
    event VaultAddressUpdated(address indexed oldVaultAddress, address indexed newVaultAddress);

    event VerificationRequestSent(bytes32 indexed requestId, string voterMatricNo, uint256 electionTokenId);

    // ====================================================================
    // Structs
    // ====================================================================
    struct ElectionSummary {
        uint256 electionId;
        string electionName;
        string electionDescription;
        IElection.ElectionState state;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 registeredVotersCount;
    }

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

    // ====================================================================
    // Core Functions
    // ====================================================================

    /**
     * @dev Sets the function client address (only owner)
     * @param _functionClient Address of the VotsEngineFunctionClient contract
     */
    function setFunctionClient(address _functionClient) external;

    /**
     * @dev Creates a new election
     * @param params Election parameters
     */
    function createElection(IElection.ElectionParams calldata params) external;

    /**
     * @dev Accredits a voter for an election
     * @param voterMatricNo Voter's matriculation number
     * @param electionTokenId Token ID of the election
     */
    function accrediteVoter(string calldata voterMatricNo, uint256 electionTokenId) external;

    /**
     * @dev Called by VotsEngineFunctionClient to fulfill voter accreditation
     * @param voterMatricNo The voter's matriculation number
     * @param electionTokenId The election token ID
     * @param messageSender The original message sender who initiated the request
     */
    function fulfillVoterAccreditation(string calldata voterMatricNo, uint256 electionTokenId, address messageSender)
        external;

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
    ) external returns (bytes32 requestId);

    /**
     * @dev Allows a voter to vote for candidates
     * @param voterMatricNo Voter's matriculation number
     * @param voterName Voter's name
     * @param candidatesList List of candidates to vote for
     * @param electionTokenId Token ID of the election
     */
    function voteCandidates(
        string calldata voterMatricNo,
        string calldata voterName,
        IElection.CandidateInfoDTO[] calldata candidatesList,
        uint256 electionTokenId
    ) external;

    // ====================================================================
    // Validation Functions
    // ====================================================================

    /**
     * @dev Validates a voter for voting
     * @param voterMatricNo Voter's matriculation number
     * @param voterName Voter's name
     * @param electionTokenId Token ID of the election
     * @return bool True if voter is valid for voting
     */
    function validateVoterForVoting(string memory voterMatricNo, string memory voterName, uint256 electionTokenId)
        external
        returns (bool);

    /**
     * @dev Validates an address as a polling unit
     * @param electionTokenId Token ID of the election
     * @return bool True if address is a valid polling unit
     */
    function validateAddressAsPollingUnit(uint256 electionTokenId) external returns (bool);

    /**
     * @dev Validates an address as a polling officer
     * @param electionTokenId Token ID of the election
     * @return bool True if address is a valid polling officer
     */
    function validateAddressAsPollingOfficer(uint256 electionTokenId) external returns (bool);

    // ====================================================================
    // Getter Functions - Engine Level
    // ====================================================================

    /**
     * @dev Returns the total number of elections created
     * @return uint256 Total election count
     */
    function getTotalElectionsCount() external view returns (uint256);

    /**
     * @dev Returns the election contract address for a given token ID
     * @param electionTokenId The token ID of the election
     * @return address Election contract address
     */
    function getElectionAddress(uint256 electionTokenId) external view returns (address);

    /**
     * @dev Returns the token ID for a given election name
     * @param electionName The name of the election
     * @return uint256 Token ID (returns 0 if not found)
     */
    function getElectionTokenId(string calldata electionName) external view returns (uint256);

    /**
     * @dev Checks if an election exists by token ID
     * @param electionTokenId The token ID of the election
     * @return bool True if election exists
     */
    function electionExistsByTokenId(uint256 electionTokenId) external view returns (bool);

    /**
     * @dev Returns the current owner of the contract
     * @return address The owner address
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the current function client address
     * @return address The function client address
     */
    function getFunctionClient() external view returns (address);

    // ====================================================================
    // Getter Functions - Election Data Forwarding
    // ====================================================================

    /**
     * @dev Returns basic election information
     * @param electionTokenId The token ID of the election
     * @return ElectionInfo Election information
     */
    function getElectionInfo(uint256 electionTokenId) external view returns (ElectionInfo memory);

    /**
     * @dev Returns election statistics
     * @param electionTokenId The token ID of the election
     * @return registeredVotersCount Number of registered voters
     * @return accreditedVotersCount Number of accredited voters
     * @return votedVotersCount Number of voters who have voted
     * @return registeredCandidatesCount Number of registered candidates
     * @return pollingOfficerCount Number of polling officers
     * @return pollingUnitCount Number of polling units
     */
    function getElectionStats(uint256 electionTokenId)
        external
        view
        returns (
            uint256 registeredVotersCount,
            uint256 accreditedVotersCount,
            uint256 votedVotersCount,
            uint256 registeredCandidatesCount,
            uint256 pollingOfficerCount,
            uint256 pollingUnitCount
        );

    /**
     * @dev Returns all voters for an election
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionVoter[] Array of voters
     */
    function getAllVoters(uint256 electionTokenId) external view returns (IElection.ElectionVoter[] memory);

    /**
     * @dev Returns all accredited voters for an election
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionVoter[] Array of accredited voters
     */
    function getAllAccreditedVoters(uint256 electionTokenId) external view returns (IElection.ElectionVoter[] memory);

    /**
     * @dev Returns all voters who have voted for an election
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionVoter[] Array of voters who have voted
     */
    function getAllVotedVoters(uint256 electionTokenId) external view returns (IElection.ElectionVoter[] memory);

    /**
     * @dev Returns all candidates for an election (as DTOs)
     * @param electionTokenId The token ID of the election
     * @return IElection.CandidateInfoDTO[] Array of candidate DTOs
     */
    function getAllCandidatesInDto(uint256 electionTokenId)
        external
        view
        returns (IElection.CandidateInfoDTO[] memory);

    /**
     * @dev Returns all candidates with vote counts (only after election ends)
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionCandidate[] Array of candidates with vote counts
     */
    function getAllCandidates(uint256 electionTokenId) external returns (IElection.ElectionCandidate[] memory);

    /**
     * @dev Returns winners for each category (handles ties)
     * @param electionTokenId The token ID of the election
     * @return IElection.ElectionWinner[][] Array of winners for each category
     */
    function getEachCategoryWinner(uint256 electionTokenId) external returns (IElection.ElectionWinner[][] memory);

    // ====================================================================
    // Utility Functions
    // ====================================================================

    /**
     * @dev Updates election state for a specific election
     * @param electionTokenId The token ID of the election
     */
    function updateElectionState(uint256 electionTokenId) external;

    /**
     * @dev Returns a summary of all elections (basic info only)
     * @return electionsSummaryList Array of election summaries
     */
    function getAllElectionsSummary() external view returns (ElectionSummary[] memory electionsSummaryList);
}

// lib/chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol

/// @title Library for encoding the input data of a Functions request into CBOR
library FunctionsRequest {
  using CBOR for CBOR.CBORBuffer;

  uint16 public constant REQUEST_DATA_VERSION = 1;
  uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

  enum Location {
    Inline, // Provided within the Request
    Remote, // Hosted through remote location that can be accessed through a provided URL
    DONHosted // Hosted on the DON's storage
  }

  enum CodeLanguage {
    JavaScript
    // In future version we may add other languages
  }

  struct Request {
    Location codeLocation; // ════════════╸ The location of the source code that will be executed on each node in the DON
    Location secretsLocation; // ═════════╸ The location of secrets that will be passed into the source code. *Only Remote secrets are supported
    CodeLanguage language; // ════════════╸ The coding language that the source code is written in
    string source; // ════════════════════╸ Raw source code for Request.codeLocation of Location.Inline, URL for Request.codeLocation of Location.Remote, or slot decimal number for Request.codeLocation of Location.DONHosted
    bytes encryptedSecretsReference; // ══╸ Encrypted URLs for Request.secretsLocation of Location.Remote (use addSecretsReference()), or CBOR encoded slotid+version for Request.secretsLocation of Location.DONHosted (use addDONHostedSecrets())
    string[] args; // ════════════════════╸ String arguments that will be passed into the source code
    bytes[] bytesArgs; // ════════════════╸ Bytes arguments that will be passed into the source code
  }

  error EmptySource();
  error EmptySecrets();
  error EmptyArgs();
  error NoInlineSecrets();

  /// @notice Encodes a Request to CBOR encoded bytes
  /// @param self The request to encode
  /// @return CBOR encoded bytes
  function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
    CBOR.CBORBuffer memory buffer = CBOR.create(DEFAULT_BUFFER_SIZE);

    buffer.writeString("codeLocation");
    buffer.writeUInt256(uint256(self.codeLocation));

    buffer.writeString("language");
    buffer.writeUInt256(uint256(self.language));

    buffer.writeString("source");
    buffer.writeString(self.source);

    if (self.args.length > 0) {
      buffer.writeString("args");
      buffer.startArray();
      for (uint256 i = 0; i < self.args.length; ++i) {
        buffer.writeString(self.args[i]);
      }
      buffer.endSequence();
    }

    if (self.encryptedSecretsReference.length > 0) {
      if (self.secretsLocation == Location.Inline) {
        revert NoInlineSecrets();
      }
      buffer.writeString("secretsLocation");
      buffer.writeUInt256(uint256(self.secretsLocation));
      buffer.writeString("secrets");
      buffer.writeBytes(self.encryptedSecretsReference);
    }

    if (self.bytesArgs.length > 0) {
      buffer.writeString("bytesArgs");
      buffer.startArray();
      for (uint256 i = 0; i < self.bytesArgs.length; ++i) {
        buffer.writeBytes(self.bytesArgs[i]);
      }
      buffer.endSequence();
    }

    return buffer.buf.buf;
  }

  /// @notice Initializes a Chainlink Functions Request
  /// @dev Sets the codeLocation and code on the request
  /// @param self The uninitialized request
  /// @param codeLocation The user provided source code location
  /// @param language The programming language of the user code
  /// @param source The user provided source code or a url
  function initializeRequest(
    Request memory self,
    Location codeLocation,
    CodeLanguage language,
    string memory source
  ) internal pure {
    if (bytes(source).length == 0) revert EmptySource();

    self.codeLocation = codeLocation;
    self.language = language;
    self.source = source;
  }

  /// @notice Initializes a Chainlink Functions Request
  /// @dev Simplified version of initializeRequest for PoC
  /// @param self The uninitialized request
  /// @param javaScriptSource The user provided JS code (must not be empty)
  function initializeRequestForInlineJavaScript(Request memory self, string memory javaScriptSource) internal pure {
    initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
  }

  /// @notice Adds Remote user encrypted secrets to a Request
  /// @param self The initialized request
  /// @param encryptedSecretsReference Encrypted comma-separated string of URLs pointing to off-chain secrets
  function addSecretsReference(Request memory self, bytes memory encryptedSecretsReference) internal pure {
    if (encryptedSecretsReference.length == 0) revert EmptySecrets();

    self.secretsLocation = Location.Remote;
    self.encryptedSecretsReference = encryptedSecretsReference;
  }

  /// @notice Adds DON-hosted secrets reference to a Request
  /// @param self The initialized request
  /// @param slotID Slot ID of the user's secrets hosted on DON
  /// @param version User data version (for the slotID)
  function addDONHostedSecrets(Request memory self, uint8 slotID, uint64 version) internal pure {
    CBOR.CBORBuffer memory buffer = CBOR.create(DEFAULT_BUFFER_SIZE);

    buffer.writeString("slotID");
    buffer.writeUInt64(slotID);
    buffer.writeString("version");
    buffer.writeUInt64(version);

    self.secretsLocation = Location.DONHosted;
    self.encryptedSecretsReference = buffer.buf.buf;
  }

  /// @notice Sets args for the user run function
  /// @param self The initialized request
  /// @param args The array of string args (must not be empty)
  function setArgs(Request memory self, string[] memory args) internal pure {
    if (args.length == 0) revert EmptyArgs();

    self.args = args;
  }

  /// @notice Sets bytes args for the user run function
  /// @param self The initialized request
  /// @param args The array of bytes args (must not be empty)
  function setBytesArgs(Request memory self, bytes[] memory args) internal pure {
    if (args.length == 0) revert EmptyArgs();

    self.bytesArgs = args;
  }
}

// src/libraries/VotsEngineLib.sol

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

// lib/chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol

/// @title The Chainlink Functions client contract
/// @notice Contract developers can inherit this contract in order to make Chainlink Functions requests
abstract contract FunctionsClient is IFunctionsClient {
  using FunctionsRequest for FunctionsRequest.Request;

  IFunctionsRouter internal immutable i_functionsRouter;

  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id);

  error OnlyRouterCanFulfill();

  constructor(address router) {
    i_functionsRouter = IFunctionsRouter(router);
  }

  /// @notice Sends a Chainlink Functions request
  /// @param data The CBOR encoded bytes data for a Functions request
  /// @param subscriptionId The subscription ID that will be charged to service the request
  /// @param callbackGasLimit the amount of gas that will be available for the fulfillment callback
  /// @return requestId The generated request ID for this request
  function _sendRequest(
    bytes memory data,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    bytes32 donId
  ) internal returns (bytes32) {
    bytes32 requestId = i_functionsRouter.sendRequest(
      subscriptionId,
      data,
      FunctionsRequest.REQUEST_DATA_VERSION,
      callbackGasLimit,
      donId
    );
    emit RequestSent(requestId);
    return requestId;
  }

  /// @notice User defined function to handle a response from the DON
  /// @param requestId The request ID, returned by sendRequest()
  /// @param response Aggregated response from the execution of the user's source code
  /// @param err Aggregated error from the execution of the user code or from the execution pipeline
  /// @dev Either response or error parameter will be set, but never both
  function _fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual;

  /// @inheritdoc IFunctionsClient
  function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external override {
    if (msg.sender != address(i_functionsRouter)) {
      revert OnlyRouterCanFulfill();
    }
    _fulfillRequest(requestId, response, err);
    emit RequestFulfilled(requestId);
  }
}

// src/Election.sol
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

// Imports

/**
 * @title Election
 * @author Ayeni-yeniyan
 * @notice This election contract stores the election information for an election in the VotsEngine.
 * Each election is owned by the VotsEngine. It holds a createdBy field which keeps the information of the election creator
 */
contract Election is IElection, Ownable {
    // ====================================================================
    // Errors
    // ====================================================================
    error Election__VoterInfoDTOCannotBeEmpty();
    error Election__UnregisteredVoterCannotBeAccredited();
    error Election__OnlyPollingUnitAllowed(address errorAddress);
    error Election__OnlyPollingOfficerAllowed(address errorAddress);
    error Election__AddressCanOnlyHaveOneRole();
    error Election__CandidatesInfoDTOCannotBeEmpty();
    error Election__AllCategoriesMustHaveOnlyOneVotedCandidate();
    error Election__InvalidStartTimeStamp();
    error Election__InvalidEndTimeStamp();
    error Election__InvalidElectionState(
        ElectionState expected,
        ElectionState actual
    );
    error Election__UnauthorizedAccountOnlyVotsEngineCanCallContract(
        address account
    );
    error Election__VoterCannotBeValidated();
    error Election__VoterAlreadyVoted();
    error Election__VoterAlreadyAccredited();
    error Election__UnknownVoter(string matricNo);
    error Election__UnaccreditedVoter(string matricNo);
    error Election__PollingOfficerAndUnitCannotBeEmpty();
    error Election__DuplicateVoter(string matricNo);
    error Election__DuplicateCandidate(string matricNo);
    error Election__DuplicateCategory();
    error Election__InvalidVote();
    error Election__RegisterCategoriesMustBeCalledBeforeRegisterVoters();
    error Election__InvalidCategory(string categoryName);

    // ====================================================================
    // State variables
    // ====================================================================
    /// @dev Creator of the election
    address private immutable _createdBy;

    /// @dev The unique token identifier for this election
    uint256 private immutable _electionUniqueTokenId;

    /// @dev The startDate for this election
    uint256 private immutable _startTimeStamp;

    /// @dev The end date for this election
    uint256 private immutable _endTimeStamp;

    /// @dev The total number of registered voters
    string[] private _registeredVotersList;

    /// @dev The total number of accredited voters
    uint256 private _accreditedVotersCount;

    /// @dev The total number of voters who have voted
    uint256 private _votedVotersCount;

    /// @dev List of registered candidates
    string[] private _registeredCandidatesList;

    /// @dev The unique election name for this election
    string private _electionName;

    /// @dev mapping of matric number(Unique identifier) to voter
    mapping(string matricNo => ElectionVoter voter) private _votersMap;

    /// @dev map of category to candidatenames to candidate
    mapping(string categoryName => mapping(string candidateMatricNo => ElectionCandidate electionCandidates))
        private _candidatesMap;

    /// @dev mapping of valid polling addresses
    mapping(address pollingAddress => bool isValid)
        private _allowedPollingUnits;

    /// Store polling officer addresses
    address[] private _pollingOfficersAddressList;

    /// Store polling unit addresses
    address[] private _pollingUnitsAddressList;

    /// @dev mapping of valid polling officer addresses
    mapping(address pollingOfficerAddress => bool isValid)
        private _allowedPollingOfficers;

    /// @dev List of all the categories in this election
    string[] private _electionCategories;

    /// @dev Election state
    ElectionState private _electionState;

    string private _description;

    // ====================================================================
    // Events
    // ====================================================================
    event AccreditedVoter(string matricNo);
    event VoterVoted();
    event ValidateAddressResult(bool result);

    // ====================================================================
    // Modifiers
    // ====================================================================

    /**
     * @dev Ensures the function is only called when the election is started
     */
    modifier onElectionStarted() {
        _updateElectionState();
        if (_electionState != ElectionState.STARTED) {
            revert Election__InvalidElectionState(
                ElectionState.STARTED,
                _electionState
            );
        }
        _;
    }

    /**
     * @dev Ensures the function is only called when the election has ended
     */
    modifier onElectionEnded() {
        // _updateElectionState();
        if (block.timestamp < _endTimeStamp) {
            revert Election__InvalidElectionState(
                ElectionState.ENDED,
                _electionState
            );
        }
        _;
    }

    modifier pollingUnitOnly(address pollingUnitAddress) {
        if (!_allowedPollingUnits[pollingUnitAddress]) {
            revert Election__OnlyPollingUnitAllowed(pollingUnitAddress);
        }
        _;
    }

    modifier pollingOfficerOnly(address pollingOfficerAddress) {
        if (!_allowedPollingOfficers[pollingOfficerAddress]) {
            revert Election__OnlyPollingOfficerAllowed(pollingOfficerAddress);
        }
        _;
    }

    modifier noUnknown(string memory matricNo) {
        if (_votersMap[matricNo].voterState == VoterState.UNKNOWN) {
            revert Election__UnknownVoter(matricNo);
        }
        _;
    }

    modifier accreditedVoterOnly(string memory matricNo) {
        if (_votersMap[matricNo].voterState == VoterState.VOTED) {
            revert Election__VoterAlreadyVoted();
        }
        if (_votersMap[matricNo].voterState != VoterState.ACCREDITED) {
            revert Election__UnaccreditedVoter(matricNo);
        }
        _;
    }

    // ====================================================================
    // Functions
    // ====================================================================

    /**
     * @dev Constructor to create a new election
     * @param createdBy Address of the creator
     * @param electionUniqueTokenId Unique identifier for this election
     * @param params Election params
     */
    constructor(
        address createdBy,
        uint256 electionUniqueTokenId,
        ElectionParams memory params
    ) Ownable(msg.sender) {
        if (block.timestamp >= params.startTimeStamp) {
            revert Election__InvalidStartTimeStamp();
        }
        if (params.startTimeStamp >= params.endTimeStamp) {
            revert Election__InvalidEndTimeStamp();
        }
        _createdBy = createdBy;
        _electionUniqueTokenId = electionUniqueTokenId;
        _electionName = params.electionName;
        _description = params.description;

        _startTimeStamp = params.startTimeStamp;
        _endTimeStamp = params.endTimeStamp;

        _electionState = ElectionState.OPENED;

        _validateCategories(params.electionCategories);
        _registerCandidates(params.candidatesList);
        _registerVoters(params.votersList);
        _registerOfficersAndUnits({
            pollingOfficerAddresses: params.pollingOfficerAddresses,
            pollingUnitAddresses: params.pollingUnitAddresses
        });
    }

    // ====================================================================
    // Public functions
    // ====================================================================
    function validateVoterForVoting(
        string memory name,
        string memory matricNo,
        address pollingUnitAddress
    ) public pollingUnitOnly(pollingUnitAddress) returns (bool validAddress) {
        ElectionVoter memory voter = _votersMap[matricNo];
        emit ValidateAddressResult(validAddress);
        return
            compareStrings(voter.name, name) &&
            voter.voterState == VoterState.ACCREDITED;
    }

    function validateAddressAsPollingUnit(
        address pollingUnitAddress
    ) public pollingUnitOnly(pollingUnitAddress) returns (bool validAddress) {
        validAddress = _allowedPollingUnits[pollingUnitAddress];
        emit ValidateAddressResult(validAddress);
    }

    function validateAddressAsPollingOfficer(
        address pollingUnitAddress
    )
        public
        pollingOfficerOnly(pollingUnitAddress)
        returns (bool validAddress)
    {
        validAddress = _allowedPollingOfficers[pollingUnitAddress];
        emit ValidateAddressResult(validAddress);
    }

    /**
     * @dev Returns Returns a list of all voters
     */
    function getAllVoters() public view returns (ElectionVoter[] memory) {
        ElectionVoter[] memory all = new ElectionVoter[](
            _registeredVotersList.length
        );
        for (uint256 i = 0; i < _registeredVotersList.length; i++) {
            all[i] = _votersMap[_registeredVotersList[i]];
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all accredited voters
     */
    function getAllAccreditedVoters()
        public
        view
        returns (ElectionVoter[] memory)
    {
        uint256 voterCount;
        ElectionVoter[] memory all = new ElectionVoter[](
            _accreditedVotersCount
        );
        for (uint256 i = 0; i < _registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[_registeredVotersList[i]];
            if (voter.voterState == VoterState.ACCREDITED) {
                all[voterCount] = voter;
                voterCount++;
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Voted voters
     */
    function getAllVotedVoters() public view returns (ElectionVoter[] memory) {
        uint256 voterCount;
        ElectionVoter[] memory all = new ElectionVoter[](_votedVotersCount);
        for (uint256 i = 0; i < _registeredVotersList.length; i++) {
            ElectionVoter memory voter = _votersMap[_registeredVotersList[i]];
            if (voter.voterState == VoterState.VOTED) {
                all[voterCount] = voter;
                voterCount++;
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Candidates
     */
    function getAllCandidatesInDto()
        public
        view
        returns (CandidateInfoDTO[] memory)
    {
        uint256 candidateCount;
        CandidateInfoDTO[] memory all = new CandidateInfoDTO[](
            _registeredCandidatesList.length
        );
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            for (uint256 j = 0; j < _registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[
                    _electionCategories[i]
                ][_registeredCandidatesList[j]];
                if (candidate.state == CandidateState.REGISTERED) {
                    all[candidateCount] = CandidateInfoDTO({
                        name: candidate.name,
                        matricNo: _registeredCandidatesList[j],
                        category: _electionCategories[i],
                        voteFor: 0,
                        voteAgainst: 0
                    });
                    candidateCount++;
                }
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Candidates
     */
    function getAllCandidates()
        public
        view
        onElectionEnded
        returns (ElectionCandidate[] memory)
    {
        uint256 candidateCount;
        ElectionCandidate[] memory all = new ElectionCandidate[](
            _registeredCandidatesList.length
        );
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            for (uint256 j = 0; j < _registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[
                    _electionCategories[i]
                ][_registeredCandidatesList[j]];
                if (candidate.state == CandidateState.REGISTERED) {
                    all[candidateCount] = candidate;
                    candidateCount++;
                }
            }
        }
        return all;
    }

    /**
     * @dev Returns Returns a list of all Candidates
     */
    function getEachCategoryWinner()
        public
        view
        onElectionEnded
        returns (ElectionWinner[][] memory)
    {
        // Assign to _electionCategories.length.
        // We will be returning a list containing a list
        // that holds the candidate that won since it is possible to tie
        ElectionWinner[][] memory allWinners = new ElectionWinner[][](
            _electionCategories.length
        );
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            string memory category = _electionCategories[i];
            uint256 maxVotes;
            uint256 winnerCount;

            // Find the maxVote for this category
            for (uint256 j = 0; j < _registeredCandidatesList.length; j++) {
                ElectionCandidate memory candidate = _candidatesMap[category][
                    _registeredCandidatesList[j]
                ];
                if (
                    candidate.state == CandidateState.REGISTERED &&
                    candidate.votes > maxVotes
                ) {
                    maxVotes = candidate.votes;
                }
            }
            // Count winners with max votes
            if (maxVotes > 0) {
                for (uint256 j = 0; j < _registeredCandidatesList.length; j++) {
                    ElectionCandidate memory candidate = _candidatesMap[
                        category
                    ][_registeredCandidatesList[j]];
                    if (
                        candidate.state == CandidateState.REGISTERED &&
                        candidate.votes == maxVotes
                    ) {
                        winnerCount++;
                    }
                }
                // Collect all winners
                ElectionWinner[] memory categoryWinners = new ElectionWinner[](
                    winnerCount
                );
                uint256 currentWinnerIndex;
                for (uint256 j = 0; j < _registeredCandidatesList.length; j++) {
                    string memory candidateMatricNo = _registeredCandidatesList[
                        j
                    ];
                    ElectionCandidate memory candidate = _candidatesMap[
                        category
                    ][candidateMatricNo];

                    if (
                        candidate.state == CandidateState.REGISTERED &&
                        candidate.votes == maxVotes
                    ) {
                        categoryWinners[currentWinnerIndex] = ElectionWinner({
                            matricNo: candidateMatricNo,
                            electionCandidate: candidate,
                            category: category
                        });
                        currentWinnerIndex++;
                    }
                }
                allWinners[i] = categoryWinners;
            } else {
                // No votes cast in this category
                allWinners[i] = new ElectionWinner[](0);
            }
        }
        return allWinners;
    }

    /**
     * @dev Returns the address of the election creator
     * @return address Creator's address
     */
    function getCreatedBy() public view returns (address) {
        return _createdBy;
    }

    /**
     * @dev Returns the description of the election
     * @return Election description
     */
    function getElectionDescription() public view returns (string memory) {
        return _description;
    }

    /**
     * @dev Returns the unique token identifier for this election
     * @return uint256 Election unique token ID
     */
    function getElectionUniqueTokenId() public view returns (uint256) {
        return _electionUniqueTokenId;
    }

    /**
     * @dev Returns the start timestamp for this election
     * @return uint256 Start timestamp
     */
    function getStartTimeStamp() public view returns (uint256) {
        return _startTimeStamp;
    }

    /**
     * @dev Returns the end timestamp for this election
     * @return uint256 End timestamp
     */
    function getEndTimeStamp() public view returns (uint256) {
        return _endTimeStamp;
    }

    /**
     * @dev Returns the name of this election
     * @return string Election name
     */
    function getElectionName() public view returns (string memory) {
        return _electionName;
    }

    /**
     * @dev Returns the current state of the election
     * @return ElectionState Current election state
     */
    function getElectionState() public view returns (ElectionState) {
        // Create a storage variable to hold the current state
        ElectionState currentState = _electionState;

        // Check if state needs updating based on current time
        uint256 currentTs = block.timestamp;
        if (
            currentTs >= _startTimeStamp &&
            currentTs < _endTimeStamp &&
            currentState != ElectionState.STARTED
        ) {
            currentState = ElectionState.STARTED;
        }
        if (currentTs >= _endTimeStamp) {
            currentState = ElectionState.ENDED;
        }

        return currentState;
    }

    /**
     * @dev Returns the total number of registered voters
     * @return uint256 Number of registered voters
     */
    function getRegisteredVotersCount() public view returns (uint256) {
        return _registeredVotersList.length;
    }

    /**
     * @dev Returns the total number of accredited voters
     * @return uint256 Number of accredited voters
     */
    function getAccreditedVotersCount() public view returns (uint256) {
        return _accreditedVotersCount;
    }

    /**
     * @dev Returns the total number of voters who have voted
     * @return uint256 Number of voters who have voted
     */
    function getVotedVotersCount() public view returns (uint256) {
        return _votedVotersCount;
    }

    /**
     * @dev Returns the total number of polling officers
     * @return uint256 Number of polling officers
     */
    function getPollingOfficerCount() public view returns (uint256) {
        return _pollingOfficersAddressList.length;
    }

    /**
     * @dev Returns the total number of polling units
     * @return uint256 Number of polling units
     */
    function getPollingUnitCount() public view returns (uint256) {
        return _pollingUnitsAddressList.length;
    }

    /**
     * @dev Returns the address of polling officers
     * @return uint256 Number of polling officers
     */
    function getPollingOfficersAddresses()
        public
        view
        returns (address[] memory)
    {
        return _pollingOfficersAddressList;
    }

    /**
     * @dev Returns the address of polling units
     * @return uint256 Number of polling units
     */
    function getPollingUnitsAddresses() public view returns (address[] memory) {
        return _pollingUnitsAddressList;
    }

    /**
     * @dev Returns the total number of registered candidates
     * @return uint256 Number of registered candidates
     */
    function getRegisteredCandidatesCount() public view returns (uint256) {
        return _registeredCandidatesList.length;
    }

    function getElectionCategories() public view returns (string[] memory) {
        return _electionCategories;
    }

    /**
     * @dev Accredits a voter with valid matric number
     * @param voterMatricNo The matric number of the voter
     * @param pollingOfficerAddress Address of the polling officer
     */
    function accrediteVoter(
        string memory voterMatricNo,
        address pollingOfficerAddress
    )
        public
        onlyOwner
        pollingOfficerOnly(pollingOfficerAddress)
        onElectionStarted
        noUnknown(voterMatricNo)
    {
        if (_votersMap[voterMatricNo].voterState == VoterState.ACCREDITED) {
            revert Election__VoterAlreadyAccredited();
        }
        _votersMap[voterMatricNo].voterState = VoterState.ACCREDITED;
        _accreditedVotersCount++;
        emit AccreditedVoter(voterMatricNo);
    }

    /**
     * @dev Allows an accredited voter to vote for candidates
     * @param voterMatricNo The matric number of the voter
     * @param voterName The name of the voter for validation
     * @param pollingUnitAddress Address of the polling unit
     * @param candidatesList List of candidates being voted for
     */
    function voteCandidates(
        string memory voterMatricNo,
        string memory voterName,
        address pollingUnitAddress,
        CandidateInfoDTO[] memory candidatesList
    )
        public
        onlyOwner
        pollingUnitOnly(pollingUnitAddress)
        onElectionStarted
        noUnknown(voterMatricNo)
        accreditedVoterOnly(voterMatricNo)
    {
        if (candidatesList.length < 1) {
            revert Election__CandidatesInfoDTOCannotBeEmpty();
        }
        if (candidatesList.length != _electionCategories.length) {
            revert Election__AllCategoriesMustHaveOnlyOneVotedCandidate();
        }
        if (!compareStrings(voterName, _votersMap[voterMatricNo].name)) {
            revert Election__VoterCannotBeValidated();
        }
        for (uint256 i = 0; i < candidatesList.length; i++) {
            CandidateInfoDTO memory candidate = candidatesList[i];
            if (!_isValidCategory(candidate.category)) {
                revert Election__InvalidCategory(candidate.category);
            }
            if (candidate.voteFor == candidate.voteAgainst) {
                revert Election__InvalidVote();
            }
            if (candidate.voteFor > candidate.voteAgainst) {
                _candidatesMap[candidate.category][candidate.matricNo].votes++;
            } else {
                _candidatesMap[candidate.category][candidate.matricNo]
                    .votesAgainst++;
            }
        }
        _votersMap[voterMatricNo].voterState = VoterState.VOTED;
        _votedVotersCount++;
        emit VoterVoted();
    }

    /**
     * @dev Updates the election state based on current time
     */
    function updateElectionState() public {
        _updateElectionState();
    }

    // ====================================================================
    // Internal functions
    // ====================================================================

    /**
     * @dev Checks if the categoryName is valid
     */
    function _isValidCategory(
        string memory categoryName
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _electionCategories.length; i++) {
            if (compareStrings(categoryName, _electionCategories[i])) {
                return true;
            }
        }
        return false;
    }

    function _containsDuplicateCategory(
        string[] memory votedCategories,
        string memory newCategory
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < votedCategories.length; i++) {
            if (compareStrings(newCategory, votedCategories[i])) {
                return true;
            }
        }
        return false;
    }

    function _validateCategories(string[] memory votedCategories) internal {
        for (uint256 i = 0; i < votedCategories.length; i++) {
            if (
                _containsDuplicateCategory(
                    _electionCategories,
                    votedCategories[i]
                )
            ) {
                revert Election__DuplicateCategory();
            } else {
                _electionCategories.push(votedCategories[i]);
            }
        }
    }

    /**
     * @dev Updates the election state based on current timestamp
     */
    function _updateElectionState() internal {
        uint256 currentTs = block.timestamp;
        if (
            currentTs >= _startTimeStamp &&
            currentTs < _endTimeStamp &&
            _electionState != ElectionState.STARTED
        ) {
            _electionState = ElectionState.STARTED;
        }
        if (currentTs >= _endTimeStamp) {
            _electionState = ElectionState.ENDED;
        }
    }

    /**
     * @dev Override function to check owner with custom error
     */
    function _checkOwner() internal view override {
        if (owner() != _msgSender()) {
            revert Election__UnauthorizedAccountOnlyVotsEngineCanCallContract(
                _msgSender()
            );
        }
    }

    /**
     * @dev Registers voters from the provided list
     * @param votersList Array of unregistered voters to register
     */
    function _registerVoters(
        VoterInfoDTO[] memory votersList
    ) internal onlyOwner {
        if (votersList.length < 1) {
            revert Election__VoterInfoDTOCannotBeEmpty();
        }
        // add all voters to votersList
        for (uint256 i = 0; i < votersList.length; i++) {
            VoterInfoDTO memory voter = votersList[i];
            // create an electionVoter from voter
            ElectionVoter memory registeredVoter = ElectionVoter({
                name: voter.name,
                voterState: VoterState.REGISTERED
            });
            // add to votersList if the state is unknown
            if (_votersMap[voter.matricNo].voterState == VoterState.UNKNOWN) {
                _votersMap[voter.matricNo] = registeredVoter;
            } else {
                revert Election__DuplicateVoter(voter.matricNo);
            }
            _registeredVotersList.push(voter.matricNo);
        }
    }

    /**
     * @dev Registers candidates from the provided list
     * @param candidatesList Array of unregistered candidates to register
     */
    function _registerCandidates(
        CandidateInfoDTO[] memory candidatesList
    ) internal onlyOwner {
        if (candidatesList.length < 1) {
            revert Election__CandidatesInfoDTOCannotBeEmpty();
        }
        // add all Candidates to _candidateMap
        for (uint256 i = 0; i < candidatesList.length; i++) {
            CandidateInfoDTO memory candidate = candidatesList[i];
            // create an ElectionCandidate from candidate
            ElectionCandidate memory registeredCandidate = ElectionCandidate({
                name: candidate.name,
                votes: 0,
                votesAgainst: 0,
                state: CandidateState.REGISTERED
            });
            if (_electionCategories.length == 0) {
                revert Election__RegisterCategoriesMustBeCalledBeforeRegisterVoters();
            }
            // Check that it is a valid election category
            for (uint256 j = 0; j < _electionCategories.length; j++) {
                if (
                    compareStrings(_electionCategories[j], candidate.category)
                ) {
                    if (
                        _candidatesMap[candidate.category][candidate.matricNo]
                            .state == CandidateState.UNKNOWN
                    ) {
                        // add to votersList
                        _candidatesMap[candidate.category][
                            candidate.matricNo
                        ] = registeredCandidate;
                    } else {
                        revert Election__DuplicateCandidate(candidate.matricNo);
                    }
                    _registeredCandidatesList.push(candidate.matricNo);
                    break;
                }
                if (j + 1 == _electionCategories.length) {
                    revert Election__InvalidCategory(candidate.category);
                }
            }
        }
    }

    /**
     * @dev Registers polling officers and polling units
     * @param pollingOfficerAddresses Array of polling officer addresses
     * @param pollingUnitAddresses Array of polling unit addresses
     */
    function _registerOfficersAndUnits(
        address[] memory pollingOfficerAddresses,
        address[] memory pollingUnitAddresses
    ) internal onlyOwner {
        if (
            pollingOfficerAddresses.length < 1 ||
            pollingUnitAddresses.length < 1
        ) {
            revert Election__PollingOfficerAndUnitCannotBeEmpty();
        }

        for (uint256 i = 0; i < pollingOfficerAddresses.length; i++) {
            address officerAddress = pollingOfficerAddresses[i];
            if (officerAddress == _createdBy) {
                revert Election__AddressCanOnlyHaveOneRole();
            }
            _allowedPollingOfficers[officerAddress] = true;
        }
        for (uint256 i = 0; i < pollingUnitAddresses.length; i++) {
            address unitAddress = pollingUnitAddresses[i];
            if (
                unitAddress == _createdBy ||
                _allowedPollingOfficers[unitAddress]
            ) {
                revert Election__AddressCanOnlyHaveOneRole();
            }
            _allowedPollingUnits[unitAddress] = true;
        }

        _pollingOfficersAddressList = pollingOfficerAddresses;
        _pollingUnitsAddressList = pollingUnitAddresses;
    }

    /**
     * @dev Compares two strings by comparing their keccak256 hashes
     * @param first First string to compare
     * @param second Second string to compare
     * @return bool True if strings are equal, false otherwise
     */
    function compareStrings(
        string memory first,
        string memory second
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(first)) ==
            keccak256(abi.encodePacked(second));
    }
}

// src/CreateElection.sol

contract CreateElection is ICreateElection, Ownable {
    constructor() Ownable(msg.sender) {}

    function createElection(address createdBy, uint256 electionUniqueTokenId, IElection.ElectionParams calldata params)
        public
        returns (address)
    {
        Election newElection =
            new Election({createdBy: createdBy, electionUniqueTokenId: electionUniqueTokenId, params: params});
        newElection.transferOwnership(owner());
        return address(newElection);
    }
}

// src/VotsEngine.sol

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

