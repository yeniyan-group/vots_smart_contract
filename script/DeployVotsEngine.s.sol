// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VotsEngine} from "../src/VotsEngine.sol";
import {CreateElection} from "../src/CreateElection.sol";
import {VotsEngineFunctionClient} from "../src/VotsEngineFunctionClient.sol";
import {VotsElectionNft} from "../src/VotsElectionNft.sol";

contract DeployVotsEngine is Script {
    VotsEngine public votsEngine;

    function run() external returns (VotsEngine) {
        HelperConfig helperConfig = new HelperConfig();
        (address router, bytes32 donId) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        CreateElection createElection = new CreateElection();
        VotsElectionNft electionNft = new VotsElectionNft();
        votsEngine = new VotsEngine({_electionCreator: address(createElection), _nftAddress: address(electionNft)});
        VotsEngineFunctionClient functionClient = new VotsEngineFunctionClient(router, donId, address(votsEngine));
        votsEngine.setFunctionClient(address(functionClient));
        createElection.transferOwnership(address(votsEngine));
        electionNft.transferOwnership(address(votsEngine));
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
        } else if (block.chainid == 43113) {
            activeNetworkConfig = getFujiC_ChainConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            router: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
            donId: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000
        });
    }

    function getFujiC_ChainConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            router: 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0,
            donId: 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000
        });
    }

    function getOrCreateAnvilConfig() public view returns (NetworkConfig memory anvilNetworkConfig) {
        if (activeNetworkConfig.router != address(0)) {
            return activeNetworkConfig;
        }

        anvilNetworkConfig =
            NetworkConfig({router: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0, donId: "fun-ethereum-sepolia-1"});
    }
}
