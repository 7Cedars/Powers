// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Powers Protocol Interface
/// @notice Interface for the Powers protocol, a Role Restricted Governance Protocol
/// @dev Derived from OpenZeppelin's Governor.sol contract
/// @author 7Cedars
pragma solidity 0.8.26;

import { PowersErrors } from "./PowersErrors.sol";
import { PowersEvents } from "./PowersEvents.sol";
import { PowersTypes } from "./PowersTypes.sol";
import { ILaw } from "./ILaw.sol";

interface IPowers is PowersErrors, PowersEvents, PowersTypes {
    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Initiates an action to be executed through a law
    /// @dev This is the entry point for all actions in the protocol, whether they require voting or not
    /// @param targetLaw The law contract to execute the action through
    /// @param lawCalldata The encoded function call data for the law
    /// @param description A human-readable description of the action
    function request(address targetLaw, bytes memory lawCalldata, string memory description) external payable;

    /// @notice Completes an action by executing the actual calls
    /// @dev Can only be called by an active law contract
    /// @param actionId The unique identifier of the action
    /// @param targets The list of contract addresses to call
    /// @param values The list of ETH values to send with each call
    /// @param calldatas The list of encoded function calls
    function fulfill(uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external payable;

    /// @notice Creates a new proposal for an action that requires voting
    /// @dev Only callable if the law requires voting (quorum > 0)
    /// @param targetLaw The law contract the proposal is for
    /// @param lawCalldata The encoded function call data for the law
    /// @param description A human-readable description of the proposal
    /// @return The unique identifier of the created proposal
    function propose(address targetLaw, bytes memory lawCalldata, string memory description)
        external
        returns (uint256);

    /// @notice Cancels an existing proposal
    /// @dev Can only be called by the original proposer
    /// @param targetLaw The law contract the proposal was for
    /// @param lawCalldata The original encoded function call data
    /// @param description The original proposal description
    /// @return The unique identifier of the cancelled proposal
    function cancel(address targetLaw, bytes memory lawCalldata, string memory description) external returns (uint256);

    /// @notice Casts a vote on an active proposal
    /// @dev Vote types: 0=Against, 1=For, 2=Abstain
    /// @param actionId The unique identifier of the proposal
    /// @param support The type of vote to cast
    function castVote(uint256 actionId, uint8 support) external;

    /// @notice Casts a vote on an active proposal with an explanation
    /// @dev Same as castVote but includes a reason string
    /// @param actionId The unique identifier of the proposal
    /// @param support The type of vote to cast
    /// @param reason A human-readable explanation for the vote
    function castVoteWithReason(uint256 actionId, uint8 support, string calldata reason) external;

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                       //
    //////////////////////////////////////////////////////////////

    /// @notice Initializes the DAO by activating its founding laws
    /// @dev Can only be called once by an admin account
    /// @param laws The list of law contracts to activate
    function constitute(address[] memory laws) external;

    /// @notice Activates a new law in the protocol
    /// @dev Can only be called through the protocol itself
    /// @param law The law contract to activate
    function adoptLaw(address law) external;

    /// @notice Deactivates an existing law
    /// @dev Can only be called through the protocol itself
    /// @param law The law contract to deactivate
    function revokeLaw(address law) external;

    /// @notice Grants a role to an account
    /// @dev Can only be called through the protocol itself
    /// @param roleId The identifier of the role to assign
    /// @param account The address to grant the role to
    function assignRole(uint32 roleId, address account) external;

    /// @notice Removes a role from an account
    /// @dev Can only be called through the protocol itself
    /// @param roleId The identifier of the role to remove
    /// @param account The address to remove the role from
    function revokeRole(uint32 roleId, address account) external;

    /// @notice Assigns a human-readable label to a role
    /// @dev Optional. Can only be called through the protocol itself
    /// @param roleId The identifier of the role to label
    /// @param label The human-readable label for the role
    function labelRole(uint32 roleId, string calldata label) external;

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                       //
    //////////////////////////////////////////////////////////////

    /// @notice Gets the current state of a proposal
    /// @param actionId The unique identifier of the proposal
    /// @return The current state of the proposal
    function state(uint256 actionId) external view returns (ActionState);

    /// @notice Checks if an account has voted on a specific proposal
    /// @param actionId The unique identifier of the proposal
    /// @param account The address to check
    /// @return True if the account has voted, false otherwise
    function hasVoted(uint256 actionId, address account) external view returns (bool);

    /// @notice Gets the current vote tallies for a proposal
    /// @param actionId The unique identifier of the proposal
    /// @return againstVotes The number of votes against
    /// @return forVotes The number of votes for
    /// @return abstainVotes The number of abstain votes
    function getProposalVotes(uint256 actionId)
        external
        view
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes);

    /// @notice Gets the deadline for voting on a proposal
    /// @param actionId The unique identifier of the proposal
    /// @return The block number at which voting ends
    function getProposalDeadline(uint256 actionId) external view returns (uint256);

    /// @notice Gets the block number since which an account has held a role
    /// @param account The address to check
    /// @param roleId The identifier of the role
    /// @return since The block number since holding the role, 0 if never held
    function hasRoleSince(address account, uint32 roleId) external view returns (uint48 since);

    /// @notice Gets the total number of accounts holding a specific role
    /// @param roleId The identifier of the role
    /// @return The number of role holders
    function getAmountRoleHolders(uint32 roleId) external view returns (uint256);

    /// @notice Checks if a law is currently active
    /// @param law The address of the law contract
    /// @return True if the law is active, false otherwise
    function getActiveLaw(address law) external view returns (bool active);

    /// @notice Checks if an account has permission to call a law
    /// @param caller The address attempting to call the law
    /// @param targetLaw The law contract to check
    /// @return True if the caller has permission, false otherwise
    function canCallLaw(address caller, address targetLaw) external view returns (bool);

    /// @notice Gets the name of the DAO
    /// @return The name string
    function name() external view returns (string memory);

    /// @notice Gets the protocol version
    /// @return The version string
    function version() external pure returns (string memory);

    /// @notice Updates the protocol's metadata URI
    /// @dev Can only be called through the protocol itself
    /// @param newUri The new URI string
    function setUri(string memory newUri) external;

    //////////////////////////////////////////////////////////////
    //                      TOKEN HANDLING                       //
    //////////////////////////////////////////////////////////////

    /// @notice Handles the receipt of a single ERC721 token
    /// @dev Implements IERC721Receiver
    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);

    /// @notice Handles the receipt of a single ERC1155 token
    /// @dev Implements IERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);

    /// @notice Handles the receipt of multiple ERC1155 tokens
    /// @dev Implements IERC1155Receiver
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
}
