// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVotsEngine {
    function fulfillVoterAccreditation(
        string calldata voterMatricNo,
        uint256 electionTokenId,
        address messageSender
    ) external;
}
