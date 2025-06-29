// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IElection} from "./IElection.sol";
interface ICreateElection {
    function createElection(
        address createdBy,
        uint256 electionUniqueTokenId,
        IElection.ElectionParams calldata params
    ) external returns (address);
}
