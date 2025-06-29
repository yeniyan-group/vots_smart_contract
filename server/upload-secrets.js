const { SecretsManager } = require("@chainlink/functions-toolkit");
const { ethers } = require("ethers");
require("dotenv").config();

async function uploadSecrets() {
    // 1. Setup provider and wallet
    const provider = new ethers.providers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);

    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    const signer = wallet.connect(provider);

    // 2. Network configuration (Sepolia testnet)
    const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
    const donId = "fun-ethereum-sepolia-1";

    // 3. Define your secrets from environment variables
    const secrets = {
        VERIFYME_CLIENT_ID: process.env.VERIFYME_CLIENT_ID,
        VERIFYME_TESTKEY: process.env.VERIFYME_TESTKEY,
    };

    // Validate that required environment variables are set
    if (!secrets.VERIFYME_CLIENT_ID || !secrets.VERIFYME_TESTKEY) {
        throw new Error("Missing required environment variables: VERIFYME_CLIENT_ID and/or VERIFYME_TESTKEY");
    }

    // 4. Initialize SecretsManager
    const secretsManager = new SecretsManager({
        signer: signer,
        functionsRouterAddress: routerAddress,
        donId: donId
    });

    await secretsManager.initialize();

    console.log("Uploading secrets to DON...");

    try {
        // 5. First, encrypt the secrets
        console.log("Encrypting secrets...");
        const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

        // 6. Upload encrypted secrets to DON
        const slotId = 1; // Slot ID for organizing secrets
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

    } catch (error) {
        console.error("❌ Error uploading secrets:", error);
        throw error;
    }
}

// Run the script
uploadSecrets()
    .then((result) => {
        console.log("\n📋 Use these values in your contract's sendRequest:");
        console.log(`Slot ID: ${result.slotId}`);
        console.log(`Version: ${result.version}`);
        console.log("\nIn your sendRequest call:");
        console.log(`- encryptedSecretsUrls: "0x" (empty for DON-hosted)`);
        console.log(`- slotId: ${result.slotId}`);
        console.log(`- version: ${result.version}`);
    })
    .catch(console.error);