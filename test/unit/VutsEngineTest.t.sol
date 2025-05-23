// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VutsEngine, Election} from "../../src/VutsEngine.sol";
import {DeployVutsEngine} from "../../script/DeployVutsEngine.s.sol";

contract VutsEngineTest is Test {
    VutsEngine public vutsEngine;
    DeployVutsEngine public deployVutsEngine;

    function setUp() public {
        deployVutsEngine = new DeployVutsEngine();
        vutsEngine = deployVutsEngine.run();
    }
}
