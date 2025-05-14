// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VutsEngine} from "../src/VutsEngine.sol";

// import {Election} from "../src/VutsEngine.sol";

contract DeployVutsEngine is Script {
    VutsEngine public vutsEngine;

    function run() external returns (VutsEngine) {
        vm.startBroadcast();
        vutsEngine = new VutsEngine();
        vm.stopBroadcast();
        return vutsEngine;
    }
}
