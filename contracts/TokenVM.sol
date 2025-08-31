// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

// This is the main contract for our Token VM.
// It will be the permanent address of our token on the Paxeer chain.
contract TokenVM {
    // The constructor is called only once when the contract is deployed.
    // It sets the owner of the contract and registers the initial facets.
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the initial diamondCut facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // The fallback function is the heart of the Diamond.
    // It's executed when a function is called on this contract that doesn't exist.
    // We use it to delegate the call to the appropriate facet.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // 1. Find the facet address for the function being called.
        // This is the corrected line that works with the official LibDiamond.sol
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        // 2. Use assembly to perform a delegatecall to the facet.
        // `delegatecall` executes the code from `facet` but in the context
        // of *this* contract's storage, balance, and identity.
        assembly {
            // Copy calldata to memory. `msg.data` contains the function signature and arguments.
            calldatacopy(0, 0, calldatasize())

            // Perform the delegatecall.
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            // Copy the return data from the call to memory.
            returndatacopy(0, 0, returndatasize())

            // `switch` handles the result of the call.
            switch result
            case 0 {
                // If the call failed, revert with the error message from the facet.
                revert(0, returndatasize())
            }
            default {
                // If the call succeeded, return the data from the facet.
                return(0, returndatasize())
            }
        }
    }

    // The receive function is executed when the contract receives plain Ether without any data.
    receive() external payable {}
}

