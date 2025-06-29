// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IVotsEngineVault
 * @author Ayeni-yeniyan
 * @notice Interface for the VotsEngineVault contract
 * Defines the contract that holds election information. This contract also creates the elections
 */
interface IVotsEngineVault {
    // ====================================================================
    // Errors
    // ====================================================================
    error VotsEngineVault__OnlyVotsEngine();

    function addElection(
        uint256 tokenId,
        string calldata electionName,
        address electionAddress
    ) external;

    function getElectionAddress(
        uint256 electionTokenId
    ) external view returns (address);
    function getElectionTokenId(
        string calldata electionName
    ) external view returns (uint256);
    function electionExistsByTokenId(
        uint256 electionTokenId
    ) external view returns (bool);
    function electionExistsByName(
        string calldata electionName
    ) external view returns (bool);
}
