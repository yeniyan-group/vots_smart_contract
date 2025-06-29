// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Election} from "../src/Election.sol";
import {IElection} from "../src/interfaces/IElection.sol";

contract CreateElection {
    function createElection(
        address createdBy,
        uint256 electionUniqueTokenId,
        IElection.ElectionParams calldata params
    ) public returns (address) {
        Election newElection = new Election({
            createdBy: createdBy,
            electionUniqueTokenId: electionUniqueTokenId,
            params: params
        });
        return address(newElection);
    }
}
