// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Facet} from "./ERC20Facet.sol";

// This is an example of a "program" that can be added to our Token VM.
// It allows token holders to store a personal message.
contract ProgramFacet {
    
    // We define a storage struct for this program's data.
    struct ProgramStorage {
        // Mapping from an address to their stored message.
        mapping(address => string) userMessages;
    }

    // A constant for this program's unique storage slot.
    bytes32 constant PROGRAM_STORAGE_POSITION = keccak256("program.storage.paxeer.messages");

    // Helper function to access the program's storage.
    function programStorage() internal pure returns (ProgramStorage storage ps) {
        bytes32 position = PROGRAM_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    // A reference to the ERC20Facet to check token balances.
    // We can interact with other facets this way.
    ERC20Facet internal erc20;

    /**
     * @notice Sets a message for the caller.
     * @dev The user must hold at least 1 token to set a message.
     * @param _message The string message to store.
     */
    function setMessage(string calldata _message) external {
        // This is how programs can interact with the token's core functionality.
        // We are checking the caller's balance before allowing them to proceed.
        require(erc20.balanceOf(msg.sender) > 0, "Must be a token holder to set a message");
        
        ProgramStorage storage ps = programStorage();
        ps.userMessages[msg.sender] = _message;
    }

    /**
     * @notice Retrieves the message for a given user.
     * @param _user The address of the user.
     * @return The user's stored message.
     */
    function getMessage(address _user) external view returns (string memory) {
        ProgramStorage storage ps = programStorage();
        return ps.userMessages[_user];
    }
}