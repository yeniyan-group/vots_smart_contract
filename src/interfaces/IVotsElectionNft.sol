// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IVotsElectionNft
 * @author Ayeni-yeniyan
 * @notice NFT contract inteface that mints tokens to election creators as proof of election creation
 * @dev This contract creates unique NFTs for each election created through the VotsEngine
 */

interface IVotsElectionNft {
    // Struct to store election data for NFT
    struct ElectionNftData {
        uint256 electionTokenId;
        string electionName;
        address creator;
        uint256 creationTimestamp;
        string electionDescription;
        uint256 startTime;
        uint256 endTime;
    }

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
     * @param nftTokenId The NFT token ID
     */
    function getElectionData(
        uint256 nftTokenId
    ) external view returns (ElectionNftData memory);

    /**
     * @dev Returns NFT token ID for a given election token ID
     * @param electionTokenId The election token ID
     */
    function getNftTokenByElectionId(
        uint256 electionTokenId
    ) external view returns (uint256);
    /**
     * @dev Returns all NFTs owned by an address
     * @param owner The owner address
     */
    function getOwnedTokens(
        address owner
    ) external view returns (uint256[] memory);

    /**
     * @dev Checks if an NFT exists for a given election
     * @param electionTokenId The election token ID
     */
    function electionNftExists(
        uint256 electionTokenId
    ) external view returns (bool);
}
