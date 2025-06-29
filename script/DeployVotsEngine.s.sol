// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VotsEngine} from "../src/VotsEngine.sol";
import {VotsEngineFunctionClient} from "../src/VotsEngineFunctionClient.sol";

contract DeployVotsEngine is Script {
    VotsEngine public votsEngine;

    function run() external returns (VotsEngine) {
        vm.startBroadcast();

        HelperConfig helperConfig = new HelperConfig();
        (address router, bytes32 donId) = helperConfig.activeNetworkConfig();
        votsEngine = new VotsEngine();
        VotsEngineFunctionClient functionClient = new VotsEngineFunctionClient(
            router,
            donId,
            address(votsEngine)
        );
        votsEngine.setFunctionClient(address(functionClient));

        vm.stopBroadcast();
        return votsEngine;
    }
}

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    struct NetworkConfig {
        address router;
        bytes32 donId;
    }
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        activeNetworkConfig = getOrCreateAnvilConfig();
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            router: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
            donId: "fun-ethereum-sepolia-1"
        });
    }

    function getOrCreateAnvilConfig()
        public
        view
        returns (NetworkConfig memory anvilNetworkConfig)
    {
        if (activeNetworkConfig.router != address(0)) {
            return activeNetworkConfig;
        }

        anvilNetworkConfig = NetworkConfig({
            router: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
            donId: "fun-ethereum-sepolia-1"
        });
    }
}
