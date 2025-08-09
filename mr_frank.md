
Traces:
  [10445191] DeployVotsEngine::run()
    ├─ [209289] → new HelperConfig@0x5aAdFB43eF8dAF45DD80F4676345b7676f1D70e3
    │   └─ ← [Return] 712 bytes of code
    ├─ [428] HelperConfig::activeNetworkConfig() [staticcall]
    │   └─ ← [Return] 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0, 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000
    ├─ [0] VM::startBroadcast()
    │   └─ ← [Return]
    ├─ [3586102] → new CreateElection@0x7ADF69eEF5cf5a4b2636D910dB58625D16119B80
    │   ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0)
    │   └─ ← [Return] 17792 bytes of code
    ├─ [2303694] → new VotsElectionNft@0xB6B8D0fDAf848dA72cED448d905016EA80A3FEF5
    │   ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0)
    │   └─ ← [Return] 11163 bytes of code
    ├─ [2591461] → new VotsEngine@0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd
    │   ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0)
    │   └─ ← [Return] 12823 bytes of code
    ├─ [1542915] → new VotsEngineFunctionClient@0xFfFF348fb53526132c5DD07befC2878a92d1493B
    │   └─ ← [Return] 7704 bytes of code
    ├─ [24279] VotsEngine::setFunctionClient(VotsEngineFunctionClient: [0xFfFF348fb53526132c5DD07befC2878a92d1493B])
    │   ├─ emit FunctionClientUpdated(oldClient: 0x0000000000000000000000000000000000000000, newClient: VotsEngineFunctionClient: [0xFfFF348fb53526132c5DD07befC2878a92d1493B])
    │   └─ ← [Return]
    ├─ [2236] CreateElection::transferOwnership(VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    │   ├─ emit OwnershipTransferred(previousOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0, newOwner: VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    │   └─ ← [Return]
    ├─ [2674] VotsElectionNft::transferOwnership(VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    │   ├─ emit OwnershipTransferred(previousOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0, newOwner: VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    │   └─ ← [Stop]
    ├─ [0] VM::stopBroadcast()
    │   └─ ← [Return]
    └─ ← [Return] VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd]


Script ran successfully.

== Return ==
0: contract VotsEngine 0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd

## Setting up 1 EVM.
==========================
Simulated On-chain Traces:

  [3586102] → new CreateElection@0x7ADF69eEF5cf5a4b2636D910dB58625D16119B80
    ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0)
    └─ ← [Return] 17792 bytes of code

  [2303694] → new VotsElectionNft@0xB6B8D0fDAf848dA72cED448d905016EA80A3FEF5
    ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0)
    └─ ← [Return] 11163 bytes of code

  [2591461] → new VotsEngine@0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd
    ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0)
    └─ ← [Return] 12823 bytes of code

  [1542915] → new VotsEngineFunctionClient@0xFfFF348fb53526132c5DD07befC2878a92d1493B
    └─ ← [Return] 7704 bytes of code

  [26279] VotsEngine::setFunctionClient(VotsEngineFunctionClient: [0xFfFF348fb53526132c5DD07befC2878a92d1493B])
    ├─ emit FunctionClientUpdated(oldClient: 0x0000000000000000000000000000000000000000, newClient: VotsEngineFunctionClient: [0xFfFF348fb53526132c5DD07befC2878a92d1493B])
    └─ ← [Return]

  [7036] CreateElection::transferOwnership(VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    ├─ emit OwnershipTransferred(previousOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0, newOwner: VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    └─ ← [Return]

  [7474] VotsElectionNft::transferOwnership(VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    ├─ emit OwnershipTransferred(previousOwner: 0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0, newOwner: VotsEngine: [0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd])
    └─ ← [Stop]


==========================

Chain 11155111

Estimated gas price: 0.00120004 gwei

Estimated total gas used for script: 14505499

Estimated amount required: 0.00001740717901996 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x8fb025c07e3284694950c0814c4911275361620751c7502e753265348ceeaffd
Contract Address: 0x7ADF69eEF5cf5a4b2636D910dB58625D16119B80
Block: 8949417
Paid: 0.00000470370247411 ETH (3919690 gas * 0.001200019 gwei)


##### sepolia
✅  [Success] Hash: 0xaa76e71a97c3655157a8cba923c1dc113e17732266ba6c056f4d3a4ee74be36d
Contract Address: 0xB6B8D0fDAf848dA72cED448d905016EA80A3FEF5
Block: 8949418
Paid: 0.000003059717244756 ETH (2549724 gas * 0.001200019 gwei)


##### sepolia
✅  [Success] Hash: 0x1d9223fccca221b30fe19a4be881b0b184543188f84450ba10721da82b55f1a8
Block: 8949418
Paid: 0.000000034687749214 ETH (28906 gas * 0.001200019 gwei)


##### sepolia
✅  [Success] Hash: 0x7b8746541952acb5d2c9dff403f682dac6865570511937f239af90ece9c35d7a
Contract Address: 0xFfFF348fb53526132c5DD07befC2878a92d1493B
Block: 8949418
Paid: 0.000002065598704795 ETH (1721305 gas * 0.001200019 gwei)


##### sepolia
✅  [Success] Hash: 0x844158dad184fc8fe7fa8d4dd8c4bf64d3f0de5feb74482481b066168e9fbd9d
Contract Address: 0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd
Block: 8949418
Paid: 0.000003424735424119 ETH (2853901 gas * 0.001200019 gwei)


##### sepolia
✅  [Success] Hash: 0x212746c7649ea85692d5ce8b99b2b96fd1533dd54214e12aee1dd40d62a8927a
Block: 8949418
Paid: 0.000000057254106509 ETH (47711 gas * 0.001200019 gwei)


##### sepolia
✅  [Success] Hash: 0xa3ff5c4c8f9a2a217d9a0b185b148f007b4418537573ff23b3b40ccba23823c3
Block: 8949418
Paid: 0.000000034162140892 ETH (28468 gas * 0.001200019 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000013379857844395 ETH (11149705 gas * avg 0.001200019 gwei)
                                                                                                                                                                                          

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (4) contracts
Start verifying contract `0x7ADF69eEF5cf5a4b2636D910dB58625D16119B80` deployed on sepolia
EVM version: cancun
Compiler version: 0.8.28
Optimizations:    200

Submitting verification for [src/CreateElection.sol:CreateElection] 0x7ADF69eEF5cf5a4b2636D910dB58625D16119B80.
Submitted contract for verification:
        Response: `OK`
        GUID: `hjdmpep1vj5ufzpxsuraed6u89pw2y4jbb91uvt7gyvjhfqzty`
        URL: https://sepolia.etherscan.io/address/0x7adf69eef5cf5a4b2636d910db58625d16119b80
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
Start verifying contract `0xB6B8D0fDAf848dA72cED448d905016EA80A3FEF5` deployed on sepolia
EVM version: cancun
Compiler version: 0.8.28
Optimizations:    200

Submitting verification for [src/VotsElectionNft.sol:VotsElectionNft] 0xB6B8D0fDAf848dA72cED448d905016EA80A3FEF5.
Submitted contract for verification:
        Response: `OK`
        GUID: `aavdn4dkeeqsywfkjwqn4n2ktfimbtjpu4nupxn5parehe1zey`
        URL: https://sepolia.etherscan.io/address/0xb6b8d0fdaf848da72ced448d905016ea80a3fef5
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `NOTOK`
Details: `Fail - Unable to verify. Compiled contract deployment bytecode does NOT match the transaction deployment bytecode.`
Error: Failed to verify contract: Checking verification result failed; Contract failed to verify.
Start verifying contract `0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd` deployed on sepolia
EVM version: cancun
Compiler version: 0.8.28
Optimizations:    200
Constructor args: 0000000000000000000000007adf69eef5cf5a4b2636d910db58625d16119b80000000000000000000000000b6b8d0fdaf848da72ced448d905016ea80a3fef5

Submitting verification for [src/VotsEngine.sol:VotsEngine] 0xBbbFfDad285D2c3bB91DDe7507EbbF0882aCE8bd.
Submitted contract for verification:
        Response: `OK`
        GUID: `vka6vn8kjykrakv1xu8kvl7jztvnuffa8enyep91l5eqkxb6jg`
        URL: https://sepolia.etherscan.io/address/0xbbbffdad285d2c3bb91dde7507ebbf0882ace8bd
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
Start verifying contract `0xFfFF348fb53526132c5DD07befC2878a92d1493B` deployed on sepolia
EVM version: cancun
Compiler version: 0.8.28
Optimizations:    200
Constructor args: 000000000000000000000000b83e47c2bc239b3bf370bc41e1459a34b41238d066756e2d657468657265756d2d7365706f6c69612d3100000000000000000000000000000000000000000000bbbffdad285d2c3bb91dde7507ebbf0882ace8bd

Submitting verification for [src/VotsEngineFunctionClient.sol:VotsEngineFunctionClient] 0xFfFF348fb53526132c5DD07befC2878a92d1493B.
Submitted contract for verification:
        Response: `OK`
        GUID: `g6ruckeg62hlhfhbiwpxlzl8yr7hatirdcpaje2dkyh8i1nzya`
        URL: https://sepolia.etherscan.io/address/0xffff348fb53526132c5dd07befc2878a92d1493b
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified

Transactions saved to: /Users/ayeniyeniyan/Documents/GitHub/vots_smart_contract/broadcast/DeployVotsEngine.s.sol/11155111/run-latest.json

Sensitive values saved to: /Users/ayeniyeniyan/Documents/GitHub/vots_smart_contract/cache/DeployVotsEngine.s.sol/11155111/run-latest.json

Error: Not all (3 / 4) contracts were verified!
make: *** [deploy-votsengine] Error 1
ayeniyeniyan@Samuels-MacBook-Pro vots_smart_contract % 