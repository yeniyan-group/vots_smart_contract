// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VotsEngine} from "../src/VotsEngine.sol";

contract DeployVotsEngine is Script {
    VotsEngine public votsEngine;

    function run() external returns (VotsEngine) {
        vm.startBroadcast();
        votsEngine = new VotsEngine();
        vm.stopBroadcast();
        return votsEngine;
    }
}
