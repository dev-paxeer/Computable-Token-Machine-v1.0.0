[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![NPM Version](https://img.shields.io/npm/v/@paxeer-foundation/ctm-contracts.svg)](https://www.npmjs.com/package/@paxeer-foundation/ctm-contracts)
[![Discord](https://img.shields.io/discord/paxeer_app?logo=discord&label=Discord)](https://discord.gg/YOUR_INVITE_CODE)
[![Twitter Follow](https://img.shields.io/twitter/follow/paxeer_app?style=social)](https://twitter.com/paxeer_app)

##  1. Introduction: Meet the Computable Token Machine (CTM)

**Headline: Beyond Value, Beyond Utility. Tokens That Think.**

For years, digital tokens have served two primary functions: storing value (like ERC-20) or representing ownership (like ERC-721). They are passive assets on the blockchain, waiting to be transferred or acted upon. The Computable Token Machine (CTM) introduces a third dimension: **computation**.

The CTM is a revolutionary new token standard where each token is a fully-fledged, modular execution environment. It's not just a token; it's a living program on the blockchain, capable of running its own applications, managing its own state, and evolving its functionality over time. Imagine a token that can run a decentralized exchange, execute a governance vote, or manage a complex character in a game—all from within itself.

This is the promise of CTM: transforming tokens from static assets into dynamic, autonomous agents on the blockchain.

-----

##  2. Core Concepts

This section explains the foundational principles of the CTM architecture.

### What is a CTM?

A Computable Token Machine is a smart contract that combines a standard token interface (like ERC-20) with a powerful, upgradeable architectural pattern known as the **Diamond Standard (EIP-2535)**.

This unique combination gives it two distinct personalities:

1.  **The Token**: On the outside, a CTM behaves like any other standard token. It can be held in a wallet, traded on exchanges, and used in DeFi protocols.
2.  **The Machine**: On the inside, the CTM acts as a proxy, routing function calls to various logic contracts called **"Programs" (or Facets)**. These Programs contain the code that the CTM can execute, and they can be added, replaced, or removed without changing the token's address.

### Key Features

  * **Infinite Extensibility**: Add new features and applications to your token after it has been deployed. Your token can evolve with your project's needs.
  * **Shared State**: All Programs within a CTM share the same core storage context. A "staking" program can directly read from and interact with a "governance" program, all within the same token.
  * **Gas Efficiency**: By organizing code into modular Programs, you can optimize gas usage and bypass the contract size limits of the EVM.
  * **True On-Chain Autonomy**: CTMs enable the creation of complex on-chain agents that can manage assets, interact with other protocols, and execute tasks based on a rich internal state.

-----

##  3. Getting Started: Your First CTM

This tutorial will guide you through deploying your own Computable Token Machine on an EVM-compatible network.

### Prerequisites

  * Node.js and npm installed.
  * A development environment like **Hardhat**.
  * An EVM wallet with funds for deployment.

### Step 1: Set Up Your Environment

Clone the official CTM repository or install via npm, which includes the core contracts and a Hardhat environment.

``` bash
npm i @paxeer-foundation/computable-token-machine
```
```bash
# Clone the repository
git clone https://github.com/dev-paxeer/Computable-Token-Machine-v1.0.0
cd Computable-Token-Machine-v1.0.0

# Install dependencies
npm install
```

### Step 2: Configure Your Deployment

In the `hardhat.config.js` file, add your network details (RPC URL) and the private key of the deploying wallet.

### Step 3: Deploy Your CTM

The deployment script handles everything: deploying the core `TokenVM.sol` proxy, all the standard facets (`DiamondCut`, `DiamondLoupe`, `Ownership`), and your token's base `ERC20Facet`.

Run the deployment command:

```bash
npx hardhat run scripts/deploy.js --network <your-network-name>
```

Upon completion, the script will output the permanent address of your new CTM token. Congratulations, your Computable Token Machine is now live\!

-----

## \#\# 4. Creating CTM Programs (Facets)

A CTM's true power comes from the custom Programs you build for it. A Program is simply a Solidity smart contract that contains logic to be executed by the CTM.

### The Anatomy of a Program

A Program must be stateless and should never declare its own state variables in the global scope. Instead, it must manage its state within a `struct` stored at a specific, unique storage slot to prevent collisions with other Programs.

**Example: `VotingProgram.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Facet} from "./ERC20Facet.sol"; // Import to interact with the token's balance

contract VotingProgram {
    
    // Define the storage for this specific program
    struct VotingStorage {
        mapping(uint256 => string) proposals;
        mapping(uint256 => mapping(address => uint256)) votes;
        uint256 proposalCount;
    }

    // A constant for this program's unique storage slot
    bytes32 constant VOTING_STORAGE_POSITION = keccak256("ctm.program.storage.voting");

    // Helper function to access the program's storage
    function votingStorage() internal pure returns (VotingStorage storage vs) {
        bytes32 position = VOTING_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    /**
     * @notice Creates a new proposal.
     * @param _description The description of the proposal.
     */
    function createProposal(string calldata _description) external {
        VotingStorage storage vs = votingStorage();
        vs.proposalCount++;
        vs.proposals[vs.proposalCount] = _description;
    }

    /**
     * @notice Casts a vote on a proposal. The vote weight is the user's token balance.
     * @param _proposalId The ID of the proposal to vote on.
     */
    function vote(uint256 _proposalId) external {
        // Here, the program interacts with the CTM's core token functionality
        uint256 voterBalance = ERC20Facet(address(this)).balanceOf(msg.sender);
        require(voterBalance > 0, "Voter must hold tokens");

        VotingStorage storage vs = votingStorage();
        vs.votes[_proposalId][msg.sender] = voterBalance;
    }
}
```

### Adding a Program to Your CTM

To add a new Program, you call the `diamondCut` function on your CTM. This function registers the new Program's functions with the CTM, making them callable at the CTM's address. This can be done through a Hardhat script or directly on a block explorer.

-----

##  5. Security Best Practices

  * **Storage Layout**: Always define your Program's state inside a `struct` and store it at a unique storage slot derived from a `keccak256` hash. Never use standard global state variables.
  * **Access Control**: The `diamondCut` function is extremely powerful. Ensure it is protected by robust ownership or governance control, typically managed by the `OwnershipFacet`.
  * **Stateless Logic**: Remember that Programs are logic contracts. They should not hold funds or have constructors that set state. All state is managed within the CTM's central storage.
-----

##  6. Resources

  * **Full Source Code**: [https://github.com/dev-paxeer/Computable-Token-Machine-v1.0.0]
  * **Live contracts**: [https://paxscan.paxeer.app/address/0x477A9f214c947e6D81b9d32b6b1883F4a4ffFb24]
  * **Community**: [https://paxeer.app/developers]
