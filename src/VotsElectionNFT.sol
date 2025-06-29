// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IVotsElectionNft} from "./interfaces/IVotsElectionNft.sol";

/**
 * @title VotsElectionNft
 * @author Ayeni-yeniyan
 * @notice NFT contract that mints tokens to election creators as proof of election creation
 * @dev This contract creates unique NFTs for each election created through the VotsEngine
 */
contract VotsElectionNft is IVotsElectionNft, ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;

    // ====================================================================
    // Custom Errors
    // ====================================================================

    error VotsElectionNft__CreatorCannotBeZeroAddress();
    error VotsElectionNft__ElectionNameCannotBeEmpty();
    error VotsElectionNft__NftAlreadyMintedForElection();
    error VotsElectionNft__TokenDoesNotExist();

    // ====================================================================
    // State Variables
    // ====================================================================

    uint256 private _tokenIdCounter;

    // Mapping from election token ID to NFT token ID
    mapping(uint256 => uint256) public electionTokenToNftToken;

    // Mapping from NFT token ID to election data
    mapping(uint256 => IVotsElectionNft.ElectionNftData) public nftTokenToElectionData;

    // ====================================================================
    // Constructor
    // ====================================================================

    constructor() Ownable(msg.sender) ERC721("VotsElection NFT", "VENFT") {}

    // ====================================================================
    // Core Functions
    // ====================================================================

    /**
     * @dev Mints an NFT to the election creator
     * @param creator Address of the election creator
     * @param electionTokenId The unique token ID of the election
     * @param electionName Name of the election
     * @param electionDescription Description of election
     * @param startTime Election start timestamp
     * @param endTime Election end timestamp
     * @return nftTokenId The ID of the minted NFT
     */
    function mintElectionNft(
        address creator,
        uint256 electionTokenId,
        string calldata electionName,
        string calldata electionDescription,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner returns (uint256 nftTokenId) {
        if (creator == address(0)) {
            revert VotsElectionNft__CreatorCannotBeZeroAddress();
        }
        if (bytes(electionName).length == 0) {
            revert VotsElectionNft__ElectionNameCannotBeEmpty();
        }
        if (electionTokenToNftToken[electionTokenId] != 0) {
            revert VotsElectionNft__NftAlreadyMintedForElection();
        }

        _tokenIdCounter++;
        nftTokenId = _tokenIdCounter;

        // Store election data
        IVotsElectionNft.ElectionNftData memory nftData = IVotsElectionNft.ElectionNftData({
            electionTokenId: electionTokenId,
            electionName: electionName,
            creator: creator,
            creationTimestamp: block.timestamp,
            electionDescription: electionDescription,
            startTime: startTime,
            endTime: endTime
        });

        nftTokenToElectionData[nftTokenId] = nftData;
        electionTokenToNftToken[electionTokenId] = nftTokenId;

        // Mint NFT to creator
        _safeMint(creator, nftTokenId);

        // Set token URI
        string memory generatedTokenURI = _generateTokenURI(nftTokenId, nftData);
        _setTokenURI(nftTokenId, generatedTokenURI);

        emit IVotsElectionNft.ElectionNftMinted(nftTokenId, electionTokenId, creator, electionName);

        return nftTokenId;
    }

    /**
     * @dev Generates metadata and token URI for the NFT
     * @param nftTokenId The NFT token ID
     * @param nftData The election data for this NFT
     * @return The complete token URI with embedded metadata
     */
    function _generateTokenURI(uint256 nftTokenId, IVotsElectionNft.ElectionNftData memory nftData)
        internal
        pure
        returns (string memory)
    {
        // Create SVG image
        string memory svg = _generateSVG(nftData);

        // Create metadata JSON
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Election Creator Certificate #',
                        nftTokenId.toString(),
                        '",',
                        '"description": "Certificate of Election Creation for ',
                        nftData.electionName,
                        '",',
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '",',
                        '"attributes": [',
                        '{"trait_type": "Election Name", "value": "',
                        nftData.electionName,
                        '"},',
                        '{"trait_type": "Election Desription", "value": "',
                        nftData.electionDescription,
                        '"},',
                        '{"trait_type": "Election Token ID", "value": "',
                        nftData.electionTokenId.toString(),
                        '"},',
                        '{"trait_type": "Creator", "value": "',
                        Strings.toHexString(uint160(nftData.creator), 20),
                        '"},',
                        '{"trait_type": "Creation Date", "value": "',
                        nftData.creationTimestamp.toString(),
                        '"}',
                        "]}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev Generates SVG image for the NFT
     * @param nftData The election data
     * @return SVG string
     */
    function _generateSVG(IVotsElectionNft.ElectionNftData memory nftData) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
                "<defs>",
                '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">',
                '<stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />',
                '<stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />',
                "</linearGradient>",
                "</defs>",
                '<rect width="400" height="400" fill="url(#grad1)" rx="20"/>',
                '<rect x="20" y="20" width="360" height="360" fill="none" stroke="white" stroke-width="2" rx="15"/>',
                '<text x="200" y="60" font-family="Arial, sans-serif" font-size="24" font-weight="bold" text-anchor="middle" fill="white">ELECTION CERTIFICATE</text>',
                '<text x="200" y="100" font-family="Arial, sans-serif" font-size="14" text-anchor="middle" fill="white">VotsEngine Creation Proof</text>',
                '<text x="50" y="140" font-family="Arial, sans-serif" font-size="14" fill="white">Election:</text>',
                '<text x="50" y="165" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="white">',
                _truncateString(nftData.electionName, 25),
                "</text>",
                '<text x="50" y="200" font-family="Arial, sans-serif" font-size="14" fill="white">Type:</text>',
                '<text x="50" y="225" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="white">',
                nftData.electionDescription,
                "</text>",
                '<text x="50" y="260" font-family="Arial, sans-serif" font-size="14" fill="white">Token ID:</text>',
                '<text x="50" y="285" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="white">#',
                nftData.electionTokenId.toString(),
                "</text>",
                '<text x="50" y="320" font-family="Arial, sans-serif" font-size="14" fill="white">Creator:</text>',
                '<text x="50" y="345" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="white">',
                _truncateAddress(nftData.creator),
                "</text>",
                '<text x="200" y="375" font-family="Arial, sans-serif" font-size="12" text-anchor="middle" fill="white">powered by YENIYAN-Group</text>',
                "</svg>"
            )
        );
    }

    /**
     * @dev Truncates a string to specified length with ellipsis
     */
    function _truncateString(string memory str, uint256 maxLength) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length <= maxLength) {
            return str;
        }

        bytes memory truncated = new bytes(maxLength - 3);
        for (uint256 i = 0; i < maxLength - 3; i++) {
            truncated[i] = strBytes[i];
        }

        return string(abi.encodePacked(truncated, "..."));
    }

    /**
     * @dev Truncates an address for display
     */
    function _truncateAddress(address addr) internal pure returns (string memory) {
        string memory addrStr = Strings.toHexString(uint160(addr), 20);
        bytes memory addrBytes = bytes(addrStr);

        bytes memory truncated = new bytes(10);
        // First 6 characters (including 0x)
        for (uint256 i = 0; i < 6; i++) {
            truncated[i] = addrBytes[i];
        }
        // Last 4 characters
        for (uint256 i = 0; i < 4; i++) {
            truncated[6 + i] = addrBytes[addrBytes.length - 4 + i];
        }

        return string(abi.encodePacked(string(truncated), "..."));
    }

    // ====================================================================
    // View Functions
    // ====================================================================

    /**
     * @dev Returns the total number of NFTs minted
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Returns election data for a given NFT token ID
     * @param nftTokenId The NFT token ID
     */
    function getElectionData(uint256 nftTokenId) external view returns (IVotsElectionNft.ElectionNftData memory) {
        if (!_exists(nftTokenId)) {
            revert VotsElectionNft__TokenDoesNotExist();
        }
        return nftTokenToElectionData[nftTokenId];
    }

    /**
     * @dev Returns NFT token ID for a given election token ID
     * @param electionTokenId The election token ID
     */
    function getNftTokenByElectionId(uint256 electionTokenId) external view returns (uint256) {
        return electionTokenToNftToken[electionTokenId];
    }

    /**
     * @dev Returns all NFTs owned by an address
     * @param owner The owner address
     */
    function getOwnedTokens(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        uint256 currentIndex = 0;

        uint256 totalTokens = _tokenIdCounter;
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                tokens[currentIndex] = i;
                currentIndex++;
                if (currentIndex >= balance) break;
            }
        }

        return tokens;
    }

    /**
     * @dev Checks if an NFT exists for a given election
     * @param electionTokenId The election token ID
     */
    function electionNftExists(uint256 electionTokenId) external view returns (bool) {
        return electionTokenToNftToken[electionTokenId] != 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return nftTokenToElectionData[tokenId].creator != address(0);
    }

    // ====================================================================
    // Override Functions
    // ====================================================================

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
