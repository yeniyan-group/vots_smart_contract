// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
