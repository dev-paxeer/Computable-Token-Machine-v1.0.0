// File: contracts/Imports.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This file's only purpose is to force Hardhat to compile the contracts
// from the NPM package and generate their artifacts for the deployment script.

import "@paxeer-foundation/computable-token-machine/contracts/facets/DiamondCutFacet.sol";
import "@paxeer-foundation/computable-token-machine/contracts/facets/DiamondLoupeFacet.sol";
import "@paxeer-foundation/computable-token-machine/contracts/facets/OwnershipFacet.sol";
import "@paxeer-foundation/computable-token-machine/contracts/TokenVM.sol";
