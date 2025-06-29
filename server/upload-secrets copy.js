const fs = require("fs");
const path = require("path");
const {
    SecretsManager,
    simulateScript,
    ReturnType,
    decodeResult
} = require("@chainlink/functions-toolkit");
const { ethers } = require("ethers");
require("dotenv").config();

async function uploadSecretsWithSimulation() {
    // 1. Validate environment variables first
    if (!process.env.SEPOLIA_RPC_URL) {
        throw new Error("SEPOLIA_RPC_URL not found in environment variables");
    }
    if (!process.env.PRIVATE_KEY) {
        throw new Error("PRIVATE_KEY not found in environment variables");
    }

    console.log("🔗 Setting up network connection...");

    // 2. Setup provider and wallet with better error handling
    let provider;
    let wallet;

    try {
        // Use ethers v5 syntax consistently (matching the original example)
        provider = new ethers.providers.JsonRpcProvider(
            process.env.SEPOLIA_RPC_URL
        );

        // Test the connection first
        // console.log("🧪 Testing network connection...");
        // const network = await provider.getNetwork();
        // console.log("✅ Connected to network:", network.name, "Chain ID:", network.chainId);

        // // Verify we're on Sepolia (chain ID 11155111)
        // if (network.chainId !== 11155111) {
        //     console.warn("⚠️  Warning: Expected Sepolia (chain ID 11155111), got chain ID:", network.chainId);
        // }

        // Create wallet
        wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
        console.log("✅ Wallet connected:", wallet.address);

        // Check wallet balance
        const balance = await wallet.getBalance();
        console.log("💰 Wallet balance:", ethers.utils.formatEther(balance), "ETH");

    } catch (networkError) {
        console.error("❌ Network connection failed:", networkError.message);

        // Provide specific troubleshooting advice
        if (networkError.message.includes("could not detect network")) {
            console.log("\n💡 Network detection failed. Try these fixes:");
            console.log("1. Check your RPC URL format (should start with https://)");
            console.log("2. Try a different RPC provider (Alchemy, Infura, or public RPC)");
            console.log("3. Check your internet connection");
            console.log("4. Current RPC URL:", process.env.SEPOLIA_RPC_URL);
        }

        throw new Error(`Network setup failed: ${networkError.message}`);
    }

    // 3. Network configuration (Sepolia testnet)
    const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
    const donId = "fun-ethereum-sepolia-1";

    // 4. Define your secrets from environment variables
    const secrets = {
        VERIFYME_CLIENT_ID: process.env.VERIFYME_CLIENT_ID,
        VERIFYME_TESTKEY: process.env.VERIFYME_TESTKEY,
    };

    // Validate that required environment variables are set
    if (!secrets.VERIFYME_CLIENT_ID || !secrets.VERIFYME_TESTKEY) {
        throw new Error("Missing required environment variables: VERIFYME_CLIENT_ID and/or VERIFYME_TESTKEY");
    }

    console.log("🔑 Secrets loaded successfully");

    // 5. Load and simulate your source code
    const sourcePath = path.resolve(__dirname, "source.js");

    if (!fs.existsSync(sourcePath)) {
        console.log("⚠️  No source.js file found for simulation. Skipping simulation step.");
        console.log("   Create a source.js file with your Chainlink Functions code to enable simulation.");
    } else {
        console.log("📋 Starting simulation...");

        const source = fs.readFileSync(sourcePath).toString();
        const args = ["63184876213", "Bunch", "Dillon", "Dillon"];

        try {
            const simulationResponse = await simulateScript({
                source: source,
                args: args,
                bytesArgs: [],
                secrets: secrets,
            });

            console.log("Simulation completed: ", simulationResponse);
            console.log("Terminal output:", simulationResponse.capturedTerminalOutput);

            const errorString = simulationResponse.errorString;
            if (errorString) {
                console.log(`❌ Error during simulation:`, errorString);
                console.log("   This might be due to:");
                console.log("   - Invalid API credentials");
                console.log("   - Network/API endpoint issues during simulation");
                console.log("   - Incorrect API request format");

                // Ask user if they want to continue despite simulation error
                const readline = require('readline');
                const rl = readline.createInterface({
                    input: process.stdin,
                    output: process.stdout
                });

                const answer = await new Promise((resolve) => {
                    rl.question('\n❓ Continue with secrets upload anyway? (y/N): ', (answer) => {
                        rl.close();
                        resolve(answer.toLowerCase());
                    });
                });

                if (answer !== 'y' && answer !== 'yes') {
                    console.log("Aborting secrets upload.");
                    return;
                }
                console.log("Continuing with secrets upload...");
            } else {
                // Try to decode the response if it exists
                const responseBytesHexstring = simulationResponse.responseBytesHexstring;
                if (ethers.utils.arrayify(responseBytesHexstring).length > 0) {
                    const returnType = ReturnType.string;
                    try {
                        const decodedResponse = decodeResult(
                            simulationResponse.responseBytesHexstring,
                            returnType
                        );
                        console.log(`✅ Decoded simulation response:`, decodedResponse);
                    } catch (decodeError) {
                        console.log("⚠️  Could not decode response. Raw response:", responseBytesHexstring);
                    }
                } else {
                    console.log("✅ Simulation completed successfully (no response data)");
                }
            }
        } catch (simulationError) {
            console.error("❌ Simulation failed:", simulationError);
            console.log("   You can still proceed with secrets upload if you're confident in your code.");

            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });

            const answer = await new Promise((resolve) => {
                rl.question('❓ Continue with secrets upload anyway? (y/N): ', (answer) => {
                    rl.close();
                    resolve(answer.toLowerCase());
                });
            });

            if (answer !== 'y' && answer !== 'yes') {
                console.log("Aborting secrets upload.");
                return;
            }
        }
    }

    // 6. Initialize SecretsManager with better error handling
    console.log("\n🔧 Initializing SecretsManager...");

    try {
        const secretsManager = new SecretsManager({
            signer: wallet,
            functionsRouterAddress: routerAddress,
            donId: donId
        });

        console.log("Connecting to Chainlink Functions network...");
        await secretsManager.initialize();
        console.log("✅ SecretsManager initialized successfully");

        console.log("\n🔐 Uploading secrets to DON...");

        // 7. First, encrypt the secrets
        console.log("Encrypting secrets...");
        const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

        // 8. Upload encrypted secrets to DON
        const slotId = 0; // Slot ID for organizing secrets
        const minutesUntilExpiration = 15; // Secrets will expire in 15 minutes

        console.log("Uploading encrypted secrets to DON...");
        const uploadResult = await secretsManager.uploadEncryptedSecretsToDON({
            encryptedSecretsHexstring: encryptedSecretsObj.encryptedSecrets,
            gatewayUrls: [
                "https://01.functions-gateway.testnet.chain.link/",
                "https://02.functions-gateway.testnet.chain.link/"
            ],
            slotId: slotId,
            minutesUntilExpiration: minutesUntilExpiration,
        });

        console.log("✅ Secrets uploaded successfully to DON!");
        console.log("Upload result:", uploadResult);
        console.log(`Secrets stored in slot ID: ${slotId}`);
        console.log(`Secret version: ${uploadResult.version}`);

        // Return the slot ID and version for use in your contract
        return {
            slotId: slotId,
            version: uploadResult.version,
            success: uploadResult.success
        };

    } catch (secretsError) {
        console.error("❌ SecretsManager error:", secretsError.message);

        if (secretsError.message.includes("could not detect network")) {
            console.log("\n💡 This is likely an RPC provider issue. Try:");
            console.log("1. Using a different RPC URL (Alchemy, Infura)");
            console.log("2. Checking if your RPC provider is working");
            console.log("3. Ensuring your internet connection is stable");
        }

        throw secretsError;
    }
}

// Run the script
uploadSecretsWithSimulation()
    .then((result) => {
        if (result) {
            console.log("\n🎉 SUCCESS! Secrets uploaded to Chainlink DON");
            console.log("📋 Use these values in your contract's sendRequest:");
            console.log(`Slot ID: ${result.slotId}`);
            console.log(`Version: ${result.version}`);
            console.log("\nIn your sendRequest call:");
            console.log(`- encryptedSecretsUrls: "0x" (empty for DON-hosted)`);
            console.log(`- slotId: ${result.slotId}`);
            console.log(`- version: ${result.version}`);
        }
    })
    .catch((error) => {
        console.error("\n💥 Script failed:", error.message);

        if (error.message.includes("network")) {
            console.log("\n🔧 Quick fixes to try:");
            console.log("1. Check your .env file has valid SEPOLIA_RPC_URL");
            console.log("2. Try this free RPC: https://rpc.sepolia.org");
            console.log("3. Or get a reliable RPC from Alchemy/Infura");
        }

        process.exit(1);
    });