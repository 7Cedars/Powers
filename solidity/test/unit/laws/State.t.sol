// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupState } from "../../TestSetup.t.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// protocol 
import { Powers } from "../../../src/Powers.sol";
import { Law } from "../../../src/Law.sol";

// law contracts being tested
import { AddressesMapping } from "../../../src/laws/state/AddressesMapping.sol";
import { StringsArray } from "../../../src/laws/state/StringsArray.sol";
import { TokensArray } from "../../../src/laws/state/TokensArray.sol";
import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
import { ElectionVotes } from "../../../src/laws/state/ElectionVotes.sol";

contract AddressMappingTest is TestSetupState {
    event AddressesMapping__Added(address account);
    event AddressesMapping__Removed(address account);

    // take this out later 
    function testParsingAddress() public {
        address mock721_ = makeAddr("mock721");
        string memory description = string.concat(
            "Anyone who knows how to mint an NFT at ", 
            Strings.toHexString(uint256(addressToInt(mock721_)), 20), 
            " can (de)select themselves for role 1."
            ); 
        console.log(mock721_); 
        console.log(description); 

        assertNotEq(description, "");
    }

    function addressToInt(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }

    function testSuccessfulAddingAddress() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding an address");

        // act + assert emit
        vm.expectEmit(true, false, false, false);
        emit AddressesMapping__Added(address(123));
        vm.prank(address(daoMock));
        bool success = Law(addressesMapping).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert execution succeeded
        assertTrue(success);

        // assert state change
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), true);
    }

    function testAddingAddressRevertsIfAlreadyAdded() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding an address");

        // First addition
        vm.prank(address(daoMock));
        bool success = Law(addressesMapping).executeLaw(address(0), lawCalldata, descriptionHash);
        assertTrue(success);

        // Second addition attempt - should revert
        vm.prank(address(daoMock));
        vm.expectRevert("Already true.");
        Law(addressesMapping).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), true);
    }

    function testSuccessfulRemovingAddress() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldataAdd = abi.encode(
            address(123), // address
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // address
            false // remove
        );
        bytes32 descriptionHashAdd = keccak256("Adding an address");
        bytes32 descriptionHashRemove = keccak256("Removing an address");

        // First add the address
        vm.prank(address(daoMock));
        bool successAdd = Law(addressesMapping).executeLaw(address(0), lawCalldataAdd, descriptionHashAdd);
        assertTrue(successAdd);

        // act + assert emit for removal
        vm.expectEmit(true, false, false, false);
        emit AddressesMapping__Removed(address(123));
        vm.prank(address(daoMock));
        bool successRemove = Law(addressesMapping).executeLaw(address(0), lawCalldataRemove, descriptionHashRemove);

        // assert execution succeeded
        assertTrue(successRemove);

        // assert state change
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
    }

    function testRemovingAddressRevertsIfNotAdded() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            false // remove
        );
        bytes32 descriptionHash = keccak256("Removing an address not added");

        // act + assert revert
        vm.prank(address(daoMock));
        vm.expectRevert("Already false.");
        Law(addressesMapping).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
    }

    function testOnlyPowersCanExecute() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding an address");

        // act + assert revert when not called by Powers
        vm.prank(alice);
        vm.expectRevert(Law__OnlyPowers.selector);
        Law(addressesMapping).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
    }
}

contract StringsArrayTest is TestSetupState {
    event StringsArray__StringAdded(string str);
    event StringsArray__StringRemoved(string str);

    function testSuccessfulAddingString() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldata = abi.encode(
            "hello world", // string to add
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding a string");

        // act + assert emit
        vm.expectEmit(true, false, false, false);
        emit StringsArray__StringAdded("hello world");
        vm.prank(address(daoMock));
        bool success = Law(stringsArray).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert execution succeeded
        assertTrue(success);

        // assert state change
        assertEq(StringsArray(stringsArray).strings(0), "hello world");
        assertEq(StringsArray(stringsArray).numberOfStrings(), 1);
    }

    function testSuccessfulRemovingString() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldataAdd = abi.encode(
            "hello world", // string to add
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            "hello world", // string to remove
            false // remove
        );

        // First add the string
        vm.prank(address(daoMock));
        bool successAdd = Law(stringsArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a string to be removed"));
        assertTrue(successAdd);

        // act + assert emit for removal
        vm.expectEmit(true, false, false, false);
        emit StringsArray__StringRemoved("hello world");
        vm.prank(address(daoMock));
        bool successRemove = Law(stringsArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a string"));

        // assert execution succeeded
        assertTrue(successRemove);

        // assert state change
        assertEq(StringsArray(stringsArray).numberOfStrings(), 0);
    }

    function testRemovingStringRevertsIfNoneAdded() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldata = abi.encode(
            "hello world", // string to remove
            false // remove
        );

        // act + assert revert
        vm.prank(address(daoMock));
        vm.expectRevert("String not found.");
        Law(stringsArray).executeLaw(address(0), lawCalldata, keccak256("Removing a string not added"));

        // assert state remains unchanged
        assertEq(StringsArray(stringsArray).numberOfStrings(), 0);
    }

    function testRemovingStringRevertsIfStringNotFound() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldataAdd = abi.encode(
            "hello world", // string to add
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            "another string", // different string to remove
            false // remove
        );

        // First add a string
        vm.prank(address(daoMock));
        bool successAdd = Law(stringsArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a string not to be removed"));
        assertTrue(successAdd);

        // act + assert revert when trying to remove different string
        vm.prank(address(daoMock));
        vm.expectRevert("String not found.");
        Law(stringsArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a string that does not exist"));

        // assert state remains unchanged
        assertEq(StringsArray(stringsArray).numberOfStrings(), 1);
        assertEq(StringsArray(stringsArray).strings(0), "hello world");
    }

    function testOnlyPowersCanExecute() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldata = abi.encode(
            "hello world", // string to add
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding a string");

        // act + assert revert when not called by Powers
        vm.prank(alice);
        vm.expectRevert(Law__OnlyPowers.selector);
        Law(stringsArray).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(StringsArray(stringsArray).numberOfStrings(), 0);
    }
}

contract TokensArrayTest is TestSetupState {
    event TokensArray__TokenAdded(address indexed tokenAddress, TokensArray.TokenType tokenType);
    event TokensArray__TokenRemoved(address indexed tokenAddress, TokensArray.TokenType tokenType);

    function testSuccessfulAddingToken() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldata = abi.encode(
            address(123), // token address
            TokensArray.TokenType.Erc20, // token type
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding a token");

        // act + assert emit
        vm.expectEmit(true, false, false, false);
        emit TokensArray__TokenAdded(address(123), TokensArray.TokenType.Erc20);
        vm.prank(address(daoMock));
        bool success = Law(tokensArray).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert execution succeeded
        assertTrue(success);

        // assert state change
        (address tokenAddress, TokensArray.TokenType tokenType) = TokensArray(tokensArray).tokens(0);
        assertEq(tokenAddress, address(123));
        assertEq(uint256(tokenType), uint256(TokensArray.TokenType.Erc20));
        assertEq(TokensArray(tokensArray).numberOfTokens(), 1);
    }

    function testSuccessfulRemovingToken() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataAdd = abi.encode(
            address(123), // token address
            TokensArray.TokenType.Erc20, // token type
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            TokensArray.TokenType.Erc20, // token type
            false // remove
        );

        // First add the token
        vm.prank(address(daoMock));
        bool successAdd = Law(tokensArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a token"));
        assertTrue(successAdd);

        // act + assert emit for removal
        vm.expectEmit(true, false, false, false);
        emit TokensArray__TokenRemoved(address(123), TokensArray.TokenType.Erc20);
        vm.prank(address(daoMock));
        bool successRemove = Law(tokensArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a token"));

        // assert execution succeeded
        assertTrue(successRemove);

        // assert state change
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
    }

    function testRemovingTokenRevertsIfNotAdded() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldata = abi.encode(
            address(123), // token address
            TokensArray.TokenType.Erc20, // token type
            false // remove
        );

        // act + assert revert
        vm.prank(address(daoMock));
        vm.expectRevert("Token not found.");
        Law(tokensArray).executeLaw(address(0), lawCalldata, keccak256("Removing a non-existent token"));

        // assert state remains unchanged
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
    }

    function testRemovingTokenRevertsIfTokenNotFound() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataAdd = abi.encode(
            address(321), // token address
            TokensArray.TokenType.Erc721, // token type
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // different token address
            TokensArray.TokenType.Erc20, // different token type
            false // remove
        );

        // First add a token
        vm.prank(address(daoMock));
        bool successAdd = Law(tokensArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a token"));
        assertTrue(successAdd);

        // act + assert revert when trying to remove different token
        vm.prank(address(daoMock));
        vm.expectRevert("Token not found.");
        Law(tokensArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a token that does not exist"));

        // assert state remains unchanged
        assertEq(TokensArray(tokensArray).numberOfTokens(), 1);
        (address tokenAddress, TokensArray.TokenType tokenType) = TokensArray(tokensArray).tokens(0);
        assertEq(tokenAddress, address(321));
        assertEq(uint256(tokenType), uint256(TokensArray.TokenType.Erc721));
    }

    function testOnlyPowersCanExecute() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldata = abi.encode(
            address(123), // token address
            TokensArray.TokenType.Erc20, // token type
            true // add
        );
        bytes32 descriptionHash = keccak256("Adding a token");

        // act + assert revert when not called by Powers
        vm.prank(alice);
        vm.expectRevert(Law__OnlyPowers.selector);
        Law(tokensArray).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
    }
}

contract NominateMeTest is TestSetupState {
    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

    function testAssignNominationSucceeds() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(
            true // nominateMe
        );
        bytes32 descriptionHash = keccak256("Nominating charlotte");

        // act + assert emit
        vm.expectEmit(true, false, false, false);
        emit NominateMe__NominationReceived(charlotte);
        vm.prank(address(daoMock));
        bool success = Law(nominateMe).executeLaw(charlotte, lawCalldata, descriptionHash);

        // assert execution succeeded
        assertTrue(success);

        // assert state change
        assertEq(NominateMe(nominateMe).nominees(charlotte), block.number);
        assertEq(NominateMe(nominateMe).nomineesCount(), 1);
        assertEq(NominateMe(nominateMe).nomineesSorted(0), charlotte);
    }

    function testAssignNominationRevertsWhenAlreadyNominated() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(
            true // nominateMe
        );
        bytes32 descriptionHash = keccak256("Nominating charlotte");

        // First nomination
        vm.prank(address(daoMock));
        bool success = Law(nominateMe).executeLaw(charlotte, lawCalldata, descriptionHash);
        assertTrue(success);

        // Second nomination attempt - should revert
        vm.prank(address(daoMock));
        vm.expectRevert("Nominee already nominated.");
        Law(nominateMe).executeLaw(charlotte, lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(NominateMe(nominateMe).nominees(charlotte), block.number);
        assertEq(NominateMe(nominateMe).nomineesCount(), 1);
        assertEq(NominateMe(nominateMe).nomineesSorted(0), charlotte);
    }

    function testRevokeNominationSucceeds() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldataAdd = abi.encode(
            true // nominateMe
        );
        bytes memory lawCalldataRemove = abi.encode(
            false // revokeNomination
        );

        // First nominate charlotte
        vm.prank(address(daoMock));
        bool successAdd = Law(nominateMe).executeLaw(charlotte, lawCalldataAdd, keccak256("Nominating charlotte"));
        assertTrue(successAdd);

        // act + assert emit for revocation
        vm.expectEmit(true, false, false, false);
        emit NominateMe__NominationRevoked(charlotte);
        vm.prank(address(daoMock));
        bool successRemove = Law(nominateMe).executeLaw(charlotte, lawCalldataRemove, keccak256("Revoking charlotte's nomination"));

        // assert execution succeeded
        assertTrue(successRemove);

        // assert state change
        assertEq(NominateMe(nominateMe).nominees(charlotte), 0);
        assertEq(NominateMe(nominateMe).nomineesCount(), 0);
    }

    function testRevokeNominationRevertsWhenNotNominated() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(
            false // revokeNomination
        );
        bytes32 descriptionHash = keccak256("Revoking non-existent nomination");

        // act + assert revert
        vm.prank(address(daoMock));
        vm.expectRevert("Nominee not nominated.");
        Law(nominateMe).executeLaw(charlotte, lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(NominateMe(nominateMe).nominees(charlotte), 0);
        assertEq(NominateMe(nominateMe).nomineesCount(), 0);
    }

    function testOnlyPowersCanExecute() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(
            true // nominateMe
        );
        bytes32 descriptionHash = keccak256("Nominating charlotte");

        // act + assert revert when not called by Powers
        vm.prank(alice);
        vm.expectRevert(Law__OnlyPowers.selector);
        Law(nominateMe).executeLaw(charlotte, lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(NominateMe(nominateMe).nominees(charlotte), 0);
        assertEq(NominateMe(nominateMe).nomineesCount(), 0);
    }
}

contract ElectionVotesTest is TestSetupState {
    event ElectionVotes__VoteCast(address voter);

    function testVoteCorrectlyRegistered() public {
        // prep
        address nominateMe = laws[3];
        address peerVote = laws[4];
        bytes memory lawCalldataNominate = abi.encode(
            true // nominateMe
        );
        bytes memory lawCalldataVote = abi.encode(
            charlotte // vote for
        );
        bytes32 descriptionHashNominate = keccak256("Nominating charlotte");
        bytes32 descriptionHashVote = keccak256("Voting for charlotte");

        // First nominate charlotte
        vm.prank(address(daoMock));
        bool successNominate = Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, descriptionHashNominate);
        assertTrue(successNominate);

        // act + assert emit
        vm.roll(51); // vote starts at block 50
        vm.expectEmit(true, false, false, false);
        emit ElectionVotes__VoteCast(alice);
        vm.prank(address(daoMock));
        bool successVote = Law(peerVote).executeLaw(alice, lawCalldataVote, descriptionHashVote);

        // assert execution succeeded
        assertTrue(successVote);

        // assert state change
        assertEq(ElectionVotes(peerVote).hasVoted(alice), true);
        assertEq(ElectionVotes(peerVote).votes(charlotte), 1);
    }

    function testVoteRevertsIfElectionNotOpen() public {
        // prep
        address nominateMe = laws[3];
        address peerVote = laws[4];
        bytes memory lawCalldataNominate = abi.encode(
            true // nominateMe
        );
        bytes memory lawCalldataVote = abi.encode(
            charlotte // vote for
        );
        bytes32 descriptionHashNominate = keccak256("Nominating charlotte");
        bytes32 descriptionHashVote = keccak256("Voting for charlotte before election opens");

        // First nominate charlotte
        vm.prank(address(daoMock));
        bool successNominate = Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, descriptionHashNominate);
        assertTrue(successNominate);

        // act + assert revert
        vm.roll(40); // vote starts at block 50
        vm.prank(address(daoMock));
        vm.expectRevert("Election not open.");
        Law(peerVote).executeLaw(alice, lawCalldataVote, descriptionHashVote);

        // assert state remains unchanged
        assertEq(ElectionVotes(peerVote).hasVoted(alice), false);
        assertEq(ElectionVotes(peerVote).votes(charlotte), 0);
    }

    function testVoteRevertsIfAlreadyVoted() public {
        // prep
        address nominateMe = laws[3];
        address peerVote = laws[4];
        bytes memory lawCalldataNominate = abi.encode(
            true // nominateMe
        );
        bytes memory lawCalldataVote = abi.encode(
            charlotte // vote for
        );
        bytes32 descriptionHashNominate = keccak256("Nominating charlotte");
        bytes32 descriptionHashVote = keccak256("Voting for charlotte");

        // First nominate charlotte
        vm.prank(address(daoMock));
        bool successNominate = Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, descriptionHashNominate);
        assertTrue(successNominate);

        // First vote
        vm.roll(51); // vote starts at block 50
        vm.prank(address(daoMock));
        bool successVote = Law(peerVote).executeLaw(alice, lawCalldataVote, descriptionHashVote);
        assertTrue(successVote);

        // act + assert revert on second vote
        vm.prank(address(daoMock));
        vm.expectRevert("Already voted.");
        Law(peerVote).executeLaw(alice, lawCalldataVote, keccak256("Attempting to vote again"));

        // assert state remains unchanged
        assertEq(ElectionVotes(peerVote).hasVoted(alice), true);
        assertEq(ElectionVotes(peerVote).votes(charlotte), 1);
    }

    function testVoteRevertsIfNotNominee() public {
        // prep
        address peerVote = laws[4];
        bytes memory lawCalldataVote = abi.encode(
            charlotte // vote for
        );
        bytes32 descriptionHash = keccak256("Voting for non-nominee");

        // act + assert revert
        vm.roll(51); // vote starts at block 50
        vm.prank(address(daoMock));
        vm.expectRevert("Not a nominee.");
        Law(peerVote).executeLaw(alice, lawCalldataVote, descriptionHash);

        // assert state remains unchanged
        assertEq(ElectionVotes(peerVote).hasVoted(alice), false);
        assertEq(ElectionVotes(peerVote).votes(charlotte), 0);
    }

    function testOnlyPowersCanExecute() public {
        // prep
        address peerVote = laws[4];
        bytes memory lawCalldata = abi.encode(
            charlotte // vote for
        );
        bytes32 descriptionHash = keccak256("Voting for charlotte");

        // act + assert revert when not called by Powers
        vm.roll(51); // vote starts at block 50
        vm.prank(alice);
        vm.expectRevert(Law__OnlyPowers.selector);
        Law(peerVote).executeLaw(alice, lawCalldata, descriptionHash);

        // assert state remains unchanged
        assertEq(ElectionVotes(peerVote).hasVoted(alice), false);
        assertEq(ElectionVotes(peerVote).votes(charlotte), 0);
    }
}
