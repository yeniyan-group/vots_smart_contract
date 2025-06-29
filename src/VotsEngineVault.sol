// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {IVotsEngineVault} from "./interfaces/IVotsEngineVault.sol";
import {IVotsEngine} from "./interfaces/IVotsEngine.sol";

/**
 * @title VotsEngineVault
 * @author Ayeni-yeniyan
 * @notice Holds all elections info. This is the token concept itself
 */
contract VotsEngineVault is IVotsEngineVault {
    address public immutable votsEngine;

    mapping(uint256 tokenId => address electionAddress)
        private s_tokenToAddress;
    mapping(string electionName => uint256 tokenId)
        private s_electionNameToTokenId;

    modifier onlyVotsEngine() {
        if (msg.sender != votsEngine) {
            revert IVotsEngineVault.VotsEngineVault__OnlyVotsEngine();
        }
        _;
    }

    modifier validElection(uint256 electionTokenId) {
        if (s_tokenToAddress[electionTokenId] == address(0))
            revert IVotsEngine.VotsEngine__ElectionNotFound();
        _;
    }

    constructor(address _votsEngine) {
        votsEngine = _votsEngine;
    }

    function addElection(
        uint256 tokenId,
        string calldata electionName,
        address electionAddress
    ) public onlyVotsEngine {
        uint256 stateTokenId = s_electionNameToTokenId[electionName];
        if (bytes(electionName).length == 0) {
            revert IVotsEngine.VotsEngine__ElectionNameCannotBeEmpty();
        }
        if (stateTokenId > 0) {
            revert IVotsEngine.VotsEngine__DuplicateElectionName();
        }
        s_tokenToAddress[tokenId] = electionAddress;
        s_electionNameToTokenId[electionName] = tokenId;
    }
    function getElectionAddress(
        uint256 electionTokenId
    ) external view validElection(electionTokenId) returns (address) {
        return s_tokenToAddress[electionTokenId];
    }
    function getElectionTokenId(
        string calldata electionName
    ) external view returns (uint256 tokenId) {
        tokenId = s_electionNameToTokenId[electionName];
        if (tokenId == 0) revert IVotsEngine.VotsEngine__ElectionNotFound();
    }
    function electionExistsByTokenId(
        uint256 electionTokenId
    ) external view returns (bool) {
        return s_tokenToAddress[electionTokenId] != address(0);
    }
    function electionExistsByName(
        string calldata electionName
    ) external view returns (bool) {
        return
            s_tokenToAddress[s_electionNameToTokenId[electionName]] !=
            address(0);
    }
}
