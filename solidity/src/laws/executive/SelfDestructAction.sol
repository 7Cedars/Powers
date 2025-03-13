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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars
pragma solidity 0.8.26;

// laws
import { Law } from "../../Law.sol";
import { LawUtils } from "../LawUtils.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract SelfDestructAction is Law {
    using ShortStrings for *;

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_, 
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_
    ) { 
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

    function handleRequest(address /*initiator*/, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (uint256 actionId, address[] memory, uint256[] memory, bytes[] memory, bytes memory)
    {
        (
            address[] memory targetsNew, 
            uint256[] memory valuesNew, 
            bytes[] memory calldatasNew
            ) = LawUtils.addSelfDestruct(targets, values, calldatas, powers);
        
        actionId = LawUtils.hashActionId(address(this), lawCalldata, descriptionHash);
        return (actionId, targetsNew, valuesNew, calldatasNew, "");
    }
}
