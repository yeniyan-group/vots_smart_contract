// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VotsElectionNft} from "../../src/VotsElectionNft.sol";
import {IVotsElectionNft} from "../../src/interfaces/IVotsElectionNft.sol";

contract VotsElectionNftTest is Test {
    VotsElectionNft public nft;

    // Test addresses
    address public owner = address(0x1);
    address public creator = address(0x2);
    address public user = address(0x3);

    // Test data
    uint256 public constant ELECTION_TOKEN_ID = 1;
    string public constant ELECTION_NAME = "Presidential Election 2024";
    string public constant ELECTION_DESCRIPTION = "General Election";
    uint256 public constant START_TIME = 1735689600; // Jan 1, 2025
    uint256 public constant END_TIME = 1767225600; // Jan 1, 2026

    function setUp() public {
        vm.prank(owner);
        nft = new VotsElectionNft();
    }

    // ====================================================================
    // Constructor Tests
    // ====================================================================

    function test_Constructor() public view {
        assertEq(nft.name(), "VotsElection NFT");
        assertEq(nft.symbol(), "VENFT");
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
    }

    // ====================================================================
    // mintElectionNft Tests
    // ====================================================================

    function test_MintElectionNft_Success() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        // Check return value
        assertEq(nftTokenId, 1);

        // Check NFT ownership
        assertEq(nft.ownerOf(nftTokenId), creator);
        assertEq(nft.balanceOf(creator), 1);
        assertEq(nft.totalSupply(), 1);

        // Check mappings
        assertEq(nft.electionTokenToNftToken(ELECTION_TOKEN_ID), nftTokenId);

        // Check election data
        IVotsElectionNft.ElectionNftData memory data = nft.getElectionData(nftTokenId);
        assertEq(data.electionTokenId, ELECTION_TOKEN_ID);
        assertEq(data.electionName, ELECTION_NAME);
        assertEq(data.creator, creator);
        assertEq(data.electionDescription, ELECTION_DESCRIPTION);
        assertEq(data.startTime, START_TIME);
        assertEq(data.endTime, END_TIME);
        assertEq(data.creationTimestamp, block.timestamp);

        // Check that NFT exists for election
        assertTrue(nft.electionNftExists(ELECTION_TOKEN_ID));

        // Check token URI is set
        string memory tokenURI = nft.tokenURI(nftTokenId);
        assertTrue(bytes(tokenURI).length > 0);
        assertTrue(_contains(tokenURI, "data:application/json;base64,"));
    }

    function test_MintElectionNft_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IVotsElectionNft.ElectionNftMinted(1, ELECTION_TOKEN_ID, creator, ELECTION_NAME);

        vm.prank(owner);
        nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);
    }

    function test_MintElectionNft_MultipleElections() public {
        // Mint first NFT
        vm.prank(owner);
        uint256 firstNftId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        // Mint second NFT
        vm.prank(owner);
        uint256 secondNftId =
            nft.mintElectionNft(user, 2, "Local Election", "Municipal Election", START_TIME + 1000, END_TIME + 1000);

        assertEq(firstNftId, 1);
        assertEq(secondNftId, 2);
        assertEq(nft.totalSupply(), 2);
        assertEq(nft.ownerOf(firstNftId), creator);
        assertEq(nft.ownerOf(secondNftId), user);
    }

    function test_MintElectionNft_RevertWhen_CreatorIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(VotsElectionNft.VotsElectionNft__CreatorCannotBeZeroAddress.selector);
        nft.mintElectionNft(address(0), ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);
    }

    function test_MintElectionNft_RevertWhen_ElectionNameIsEmpty() public {
        vm.prank(owner);
        vm.expectRevert(VotsElectionNft.VotsElectionNft__ElectionNameCannotBeEmpty.selector);
        nft.mintElectionNft(creator, ELECTION_TOKEN_ID, "", ELECTION_DESCRIPTION, START_TIME, END_TIME);
    }

    function test_MintElectionNft_RevertWhen_NftAlreadyMintedForElection() public {
        // Mint first NFT
        vm.prank(owner);
        nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        // Try to mint another NFT for the same election
        vm.prank(owner);
        vm.expectRevert(VotsElectionNft.VotsElectionNft__NftAlreadyMintedForElection.selector);
        nft.mintElectionNft(user, ELECTION_TOKEN_ID, "Another Election", ELECTION_DESCRIPTION, START_TIME, END_TIME);
    }

    function test_MintElectionNft_RevertWhen_NotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);
    }

    // ====================================================================
    // View Function Tests
    // ====================================================================

    function test_GetElectionData_Success() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        IVotsElectionNft.ElectionNftData memory data = nft.getElectionData(nftTokenId);

        assertEq(data.electionTokenId, ELECTION_TOKEN_ID);
        assertEq(data.electionName, ELECTION_NAME);
        assertEq(data.creator, creator);
        assertEq(data.electionDescription, ELECTION_DESCRIPTION);
        assertEq(data.startTime, START_TIME);
        assertEq(data.endTime, END_TIME);
        assertGt(data.creationTimestamp, 0);
    }

    function test_GetElectionData_RevertWhen_TokenDoesNotExist() public {
        vm.expectRevert(VotsElectionNft.VotsElectionNft__TokenDoesNotExist.selector);
        nft.getElectionData(999);
    }

    function test_GetNftTokenByElectionId() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        assertEq(nft.getNftTokenByElectionId(ELECTION_TOKEN_ID), nftTokenId);
        assertEq(nft.getNftTokenByElectionId(999), 0); // Non-existent election
    }

    function test_GetOwnedTokens_SingleToken() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        uint256[] memory ownedTokens = nft.getOwnedTokens(creator);
        assertEq(ownedTokens.length, 1);
        assertEq(ownedTokens[0], nftTokenId);

        // Check empty array for non-owner
        uint256[] memory emptyTokens = nft.getOwnedTokens(user);
        assertEq(emptyTokens.length, 0);
    }

    function test_GetOwnedTokens_MultipleTokens() public {
        // Mint multiple NFTs to the same creator
        vm.startPrank(owner);

        uint256 firstNftId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        uint256 secondNftId =
            nft.mintElectionNft(creator, 2, "Second Election", ELECTION_DESCRIPTION, START_TIME, END_TIME);

        vm.stopPrank();

        uint256[] memory ownedTokens = nft.getOwnedTokens(creator);
        assertEq(ownedTokens.length, 2);

        // Check that both tokens are in the array
        bool foundFirst = false;
        bool foundSecond = false;
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            if (ownedTokens[i] == firstNftId) foundFirst = true;
            if (ownedTokens[i] == secondNftId) foundSecond = true;
        }
        assertTrue(foundFirst);
        assertTrue(foundSecond);
    }

    function test_ElectionNftExists() public {
        assertFalse(nft.electionNftExists(ELECTION_TOKEN_ID));

        vm.prank(owner);
        nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        assertTrue(nft.electionNftExists(ELECTION_TOKEN_ID));
        assertFalse(nft.electionNftExists(999));
    }

    function test_TotalSupply() public {
        assertEq(nft.totalSupply(), 0);

        vm.startPrank(owner);

        nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);
        assertEq(nft.totalSupply(), 1);

        nft.mintElectionNft(user, 2, "Second Election", ELECTION_DESCRIPTION, START_TIME, END_TIME);
        assertEq(nft.totalSupply(), 2);

        vm.stopPrank();
    }

    // ====================================================================
    // Token URI Tests
    // ====================================================================

    function test_TokenURI_ContainsExpectedData() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        string memory tokenURI = nft.tokenURI(nftTokenId);

        // Basic checks
        assertTrue(bytes(tokenURI).length > 0);
        assertTrue(_contains(tokenURI, "data:application/json;base64,"));

        // The tokenURI should be a base64 encoded JSON
        // We can't easily decode it in Solidity, but we can check it exists
        assertGt(bytes(tokenURI).length, 100); // Should be a substantial URI
    }

    // ====================================================================
    // ERC721 Standard Tests
    // ====================================================================

    function test_ERC721_Transfer() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        // Transfer from creator to user
        vm.prank(creator);
        nft.transferFrom(creator, user, nftTokenId);

        assertEq(nft.ownerOf(nftTokenId), user);
        assertEq(nft.balanceOf(creator), 0);
        assertEq(nft.balanceOf(user), 1);
    }

    function test_ERC721_Approve() public {
        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(creator, ELECTION_TOKEN_ID, ELECTION_NAME, ELECTION_DESCRIPTION, START_TIME, END_TIME);

        // Approve user to transfer the NFT
        vm.prank(creator);
        nft.approve(user, nftTokenId);

        assertEq(nft.getApproved(nftTokenId), user);

        // User can now transfer the NFT
        vm.prank(user);
        nft.transferFrom(creator, user, nftTokenId);

        assertEq(nft.ownerOf(nftTokenId), user);
    }

    function test_SupportsInterface() public view {
        // ERC721
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(nft.supportsInterface(0x5b5e139f));
        // ERC165
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    // ====================================================================
    // Fuzz Tests
    // ====================================================================

    function testFuzz_MintElectionNft(
        uint256 _electionTokenId,
        string calldata _electionName,
        string calldata _electionDescription,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        address _creator = makeAddr(_electionName);
        // Skip invalid inputs
        vm.assume(_creator != address(0));
        vm.assume(bytes(_electionName).length > 0);
        vm.assume(bytes(_electionName).length <= 100); // Reasonable limit
        vm.assume(bytes(_electionDescription).length <= 200); // Reasonable limit

        vm.prank(owner);
        uint256 nftTokenId =
            nft.mintElectionNft(_creator, _electionTokenId, _electionName, _electionDescription, _startTime, _endTime);

        assertEq(nft.ownerOf(nftTokenId), _creator);
        assertEq(nft.electionTokenToNftToken(_electionTokenId), nftTokenId);
        assertTrue(nft.electionNftExists(_electionTokenId));

        IVotsElectionNft.ElectionNftData memory data = nft.getElectionData(nftTokenId);
        assertEq(data.creator, _creator);
        assertEq(data.electionTokenId, _electionTokenId);
        assertEq(data.electionName, _electionName);
        assertEq(data.electionDescription, _electionDescription);
        assertEq(data.startTime, _startTime);
        assertEq(data.endTime, _endTime);
    }

    // ====================================================================
    // Helper Functions
    // ====================================================================

    function _contains(string memory str, string memory substring) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory subBytes = bytes(substring);

        if (subBytes.length > strBytes.length) return false;

        for (uint256 i = 0; i <= strBytes.length - subBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < subBytes.length; j++) {
                if (strBytes[i + j] != subBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }
}
