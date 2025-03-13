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

/// @notice A base contract that executes a preset action.
///
/// The logic:
/// - anythe lawCalldata includes a single bool. If the bool is set to true, it will aend the present calldatas to the execute function of the Powers protocol.
///
/// @author 7Cedars, 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtils } from "../LawUtils.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";


///// ONLY FOR TESTING /////    
import "forge-std/Test.sol";
///// ONLY FOR TESTING /////

contract PresetAction is Law {
    using ShortStrings for *;

    /// the targets, values and calldatas to be used in the calls: set at construction.
    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;

    /// @notice constructor of the law
    /// @param name_ the name of the law.
    /// @param description_ the description of the law.
    /// @param powers_ the address of the core governance protocol
    /// @param targets_ the targets to use in the calls.
    /// @param allowedRole_ the role that is allowed to execute this law
    /// @param config_ the configuration of the law
    /// @param values_ the values to use in the calls.
    /// @param calldatas_ the calldatas to use in the calls.
    constructor(
        // inherited from Law
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // specific to preset action
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_
    )  {
        LawUtils.checkConstructorInputs(powers_, name_);
        name = name_.toShortString();
        powers = powers_;
        allowedRole = allowedRole_;
        config = config_;

        targets = targets_;
        values = values_;
        calldatas = calldatas_;

        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, ""); // empty params
    }

    /// @notice execute the law.
    function handleRequest(address /*initiator*/, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (uint256 actionId, address[] memory, uint256[] memory, bytes[] memory, bytes memory)
    {
        console.log("@PresetAction: waypoint 1");
        actionId = _hashActionId(address(this), lawCalldata, descriptionHash);
        console.log("@PresetAction: waypoint 2");
        console.log("@PresetAction: actionId", actionId);
        return (actionId, targets, values, calldatas, "");  
    }
}
