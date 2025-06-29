// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Election} from "../src/Election.sol";
import {ICreateElection} from "../src/interfaces/ICreateElection.sol";
import {IElection} from "../src/interfaces/IElection.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CreateElection is ICreateElection, Ownable {
    constructor() Ownable(msg.sender) {}
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
        newElection.transferOwnership(owner());
        return address(newElection);
    }
}
