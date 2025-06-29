# VotsEngine - Decentralized Voting System

A comprehensive blockchain-based voting system built on Ethereum that ensures transparent, secure, and tamper-proof elections.

## 🚀 Overview

VotsEngine is a smart contract-based voting platform that tokenizes elections and provides a complete end-to-end voting solution. The system consists of two main contracts:

- **VotsEngine**: Core contract that manages election creation and acts as a factory
- **Election**: Individual election contracts with comprehensive voting logic

## ✨ Features

### Core Functionality
- **Election Creation**: Create multiple elections with unique identifiers
- **Voter Registration**: Register voters with matriculation numbers
- **Candidate Registration**: Register candidates across multiple categories
- **Voter Accreditation**: Polling officers can accredit registered voters
- **Secure Voting**: Accredited voters can cast votes through polling units
- **Real-time Results**: Track election statistics and results
- **Winner Determination**: Automatic winner calculation with tie handling

### Security Features
- **Role-based Access Control**: Distinct roles for polling officers and units
- **State Management**: Elections progress through OPENED → STARTED → ENDED states
- **Duplicate Prevention**: Protection against duplicate voters and candidates
- **Time-based Controls**: Elections automatically start and end based on timestamps
- **Validation Checks**: Comprehensive input validation and error handling

### Advanced Features
- **Multi-category Elections**: Support for elections with multiple position categories
- **Tie Handling**: Automatic detection and reporting of tied results
- **Election Tokenization**: Each election gets a unique token ID for reference
- **Comprehensive Statistics**: Detailed voter and candidate analytics
- **Event Logging**: All major actions emit events for transparency

## 📋 Prerequisites

- Solidity ^0.8.21
- OpenZeppelin Contracts (for Ownable functionality)
- Ethereum development environment (foundry)

## 🛠 Installation

1. Clone the repository:
```bash
git clone https://github.com/yeniyan-group/vots_smart_contract.git
cd vots_smart_contract
```

2. Install dependencies:
```bash
make install
```

3. Compile contracts:
```bash
forge build
```

## 🌐 Live Deployment

The VotsEngine contract is currently deployed and live on Sepolia testnet:

**Contract Address**: `0xbC9aFaB1b833427195F9674b0f34B501b408f810 `

**NftContract Address**: `0x7b80Dcda97907eFF4D99655223437E4689E559c6`

**Network**: Sepolia Testnet
- **Chain ID**: 11155111
- **Block Explorer**: https://sepolia.etherscan.io/address/0xbC9aFaB1b833427195F9674b0f34B501b408f810
- **NftContract Block Explorer**: https://sepolia.etherscan.io/address/0x7b80Dcda97907eFF4D99655223437E4689E559c6

### Interacting with the Live Contract

You can interact with the deployed contract using:

1. **Etherscan Interface**: Visit the contract on Sepolia Etherscan to read contract state
2. **Web3 Libraries**: Connect using ethers.js or web3.js
3. **Frontend Applications**: Build dApps that interact with the contract

```javascript
// Example using ethers.js
const contractAddress = "0xbC9aFaB1b833427195F9674b0f34B501b408f810";
const VotsEngine = new ethers.Contract(contractAddress, abi, signer);

// Get total elections count
const totalElections = await VotsEngine.getTotalElectionsCount();
```

## 📖 Usage

### Deploying the System

The VotsEngine is already deployed on Sepolia testnet at `0xbC9aFaB1b833427195F9674b0f34B501b408f810`.

For local development or custom deployments:
```solidity
// Deploy VotsEngine contract
VotsEngine VotsEngine = new VotsEngine();
```

Or connect to the existing deployment:
```javascript
const VotsEngine = new ethers.Contract(
    "0xbC9aFaB1b833427195F9674b0f34B501b408f810", 
    VotsEngineABI, 
    provider
);
```

### Creating an Election

```solidity
// Prepare election data
VoterInfoDTO[] memory voters = [
    VoterInfoDTO("John Doe", "MAT001"),
    VoterInfoDTO("Jane Smith", "MAT002")
];

CandidateInfoDTO[] memory candidates = [
    CandidateInfoDTO("Alice Johnson", "CAN001", "President"),
    CandidateInfoDTO("Bob Wilson", "CAN002", "President")
];

address[] memory pollingUnits = [0x123..., 0x456...];
address[] memory pollingOfficers = [0x789..., 0xabc...];
string[] memory categories = ["President", "Vice President"];

// Create election
VotsEngine.createElection(
    startTimestamp,
    endTimestamp,
    "Student Union Election 2024",
    "Student Union Election 2024 description",
    candidates,
    voters,
    pollingUnits,
    pollingOfficers,
    categories
);
```

### Voting Process

1. **Accredit Voter** (Polling Officer):
```solidity
VotsEngine.accrediteVoter("MAT001", electionTokenId);
```

2. **Cast Vote** (Polling Unit):
```solidity
CandidateInfoDTO[] memory votes = [
    CandidateInfoDTO("Alice Johnson", "CAN001", "President")
];
VotsEngine.voteCandidates("MAT001", "John Doe", votes, electionTokenId);
```

3. **Get Results** (After election ends):
```solidity
ElectionWinner[][] memory winners = VotsEngine.getEachCategoryWinner(electionTokenId);
```

## 📊 Contract Architecture

### VotsEngine Contract
- Manages multiple elections
- Acts as a factory for Election contracts
- Provides unified interface for all election operations
- Maintains election registry with token IDs

### Election Contract
- Handles individual election logic
- Manages voters, candidates, and voting process
- Implements state transitions and validations
- Calculates results and determines winners

## 🔐 Security Considerations

### Access Control
- Only VotsEngine can interact with Election contracts
- Polling officers can only accredit voters
- Polling units can only process votes
- Addresses cannot have multiple roles

### Validation
- Comprehensive input validation
- Duplicate prevention mechanisms
- State-based operation restrictions
- Time-based access controls

### Transparency
- All operations emit events
- Immutable vote records
- Public result verification
- Open-source smart contracts

## 📚 API Reference

### VotsEngine Functions

#### Election Management
- `createElection()` - Create a new election
- `getTotalElectionsCount()` - Get total number of elections
- `getAllElectionsSummary()` - Get summary of all elections

#### Voting Operations
- `accrediteVoter()` - Accredit a voter for voting
- `voteCandidates()` - Cast votes for candidates

#### Data Retrieval
- `getElectionInfo()` - Get basic election information
- `getElectionStats()` - Get comprehensive election statistics
- `getAllVoters()` - Get all registered voters
- `getAllCandidates()` - Get all candidates with results
- `getEachCategoryWinner()` - Get winners for each category

### Election Functions

#### Voter Management
- `getAllVoters()` - Get all registered voters
- `getAllAccreditedVoters()` - Get accredited voters
- `getAllVotedVoters()` - Get voters who have voted

#### Results
- `getAllCandidates()` - Get candidates with vote counts
- `getEachCategoryWinner()` - Get category winners

## 🎯 Use Cases

- **Academic Institutions**: Student union elections, faculty elections
- **Corporate Governance**: Board elections, shareholder voting
- **Community Organizations**: Member elections, policy voting
- **Political Elections**: Local government, party primaries
- **DAO Governance**: Decentralized organization voting

## 🚨 Error Handling

The system includes comprehensive error handling for common scenarios:

- Invalid timestamps
- Duplicate registrations
- Unauthorized access attempts
- Invalid election states
- Missing required data
- Voting violations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Ayeni-yeniyan** - *Smart Contract Developer*

## 🙏 Acknowledgments

- OpenZeppelin for secure contract templates
- Ethereum community for development tools
- Contributors and testers

## 📞 Support

For questions, issues, or contributions, please:
- Open an issue on GitHub
- Contact the development team
- Review the documentation

---

**Note**: This is a smart contract system that handles sensitive voting data. Please ensure proper testing and security audits before deploying to mainnet.
