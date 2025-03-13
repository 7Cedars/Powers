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

import { Law } from "../../../Law.sol";
import { Powers } from "../../../Powers.sol";
import { LawUtils } from "../../LawUtils.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract NftSelfSelect is Law {
    using ShortStrings for *;

    uint32 public roleId;
    address public erc721Token;
    
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        uint32 roleId_,
        address erc721Token_
    ) {
        LawUtils.checkConstructorInputs(powers_, name_);
        name = name_.toShortString();
        powers = powers_;
        allowedRole = allowedRole_;
        config = config_;

        erc721Token = erc721Token_;
        roleId = roleId_;

        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, "");
    }

    function handleRequest(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        LawUtils.nftCheck(initiator, erc721Token);
        actionId = LawUtils.hashActionId(address(this), lawCalldata, descriptionHash);

        (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, roleId, initiator);

        return (actionId, targets, values, calldatas, "");
    }
}
