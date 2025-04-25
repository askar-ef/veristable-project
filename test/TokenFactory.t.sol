// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenFactory.sol";
import "../src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;
    address public alice;
    address public bob;
    address public owner;

    event TokenCreated(address indexed tokenAddress, string name, string symbol, address owner);
    event TokenAddedToAVS(address indexed tokenAddress);
    event TokenRemovedFromAVS(address indexed tokenAddress);

    function setUp() public {
        // Deploy the factory and set up test addresses
        owner = address(this); // The deployer is the owner
        factory = new TokenFactory();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    function testCreateToken() public {
        vm.startPrank(owner);

        // Create a token with default owner (msg.sender)
        address tokenAddress = factory.createToken("My Token", "MTK", address(0));
        Token newToken = Token(tokenAddress);
        newToken.mint(owner, 1_000_000 * 1e18); // Mint 1 million tokens to the contract owner for testing purpos

        // Verify token properties
        assertEq(newToken.name(), "My Token");
        assertEq(newToken.symbol(), "MTK");
        assertEq(newToken.totalSupply(), 1_000_000 * 1e18);
        assertEq(newToken.balanceOf(owner), 1_000_000 * 1e18);
        assertEq(newToken.owner(), owner);

        // Verify AVSTokens mapping
        assertTrue(factory.AVSTokens(tokenAddress));

        // Verify token tracking
        address[] memory userTokens = factory.getTokensByUser(owner);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], tokenAddress);
        assertEq(factory.getUserTokenCount(owner), 1);

        vm.stopPrank();
    }

     function testCreateTokenWithCustomOwner() public {
        vm.startPrank(owner);

        // Create a token with custom owner (alice)
        address tokenAddress = factory.createToken("Custom Token", "CTKN", alice);
        Token newToken = Token(tokenAddress);

        // Verify token properties
        assertEq(newToken.name(), "Custom Token");
        assertEq(newToken.symbol(), "CTKN");
        assertEq(newToken.owner(), alice);
        
        // Verify AVSTokens mapping
        assertTrue(factory.AVSTokens(tokenAddress));

        // Verify token tracking
        address[] memory userTokens = factory.getTokensByUser(alice);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], tokenAddress);
        assertEq(factory.getUserTokenCount(alice), 1);

        vm.stopPrank();
    }

    function testMultipleTokenCreation() public {
        vm.startPrank(owner);

        // Create tokens for different users
        address token1Address = factory.createToken("Token1", "TK1", alice);
        address token2Address = factory.createToken("Token2", "TK2", bob);

        Token token1 = Token(token1Address);
        Token token2 = Token(token2Address);

        // Verify tokens are different and have correct properties
        assertTrue(token1Address != token2Address);
        assertEq(token1.owner(), alice);
        assertEq(token2.owner(), bob);
        
        // Verify token tracking for both users
        assertEq(factory.getUserTokenCount(alice), 1);
        assertEq(factory.getUserTokenCount(bob), 1);

        // Verify all tokens array
        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 2);
        assertEq(allTokens[0], token1Address);
        assertEq(allTokens[1], token2Address);

        vm.stopPrank();
    }

    function testAddAndRemoveFromAVSTokens() public {
        vm.startPrank(owner);

        // Create a token
        address tokenAddress = factory.createToken("My Token", "MTK", address(0));
        assertTrue(factory.AVSTokens(tokenAddress));

        // Remove token from AVSTokens
        factory.removeFromAVSTokens(tokenAddress);
        assertFalse(factory.AVSTokens(tokenAddress));

        // Add token back to AVSTokens
        factory.addToAVSTokens(tokenAddress);
        assertTrue(factory.AVSTokens(tokenAddress));

        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerTriesToAddToAVSTokens() public {
        vm.startPrank(owner);

        // Create a token
        address tokenAddress = factory.createToken("My Token", "MTK", address(0));

        vm.stopPrank();

        // Try to add token to AVSTokens as non-owner
        vm.prank(alice);
        // vm.expectRevert("Ownable: caller is not the owner");
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        factory.addToAVSTokens(tokenAddress);
    }

    function testGetTokensByUser() public {
        vm.startPrank(owner);

        // Create multiple tokens for alice
        address token1 = factory.createToken("Token1", "TK1", alice);
        address token2 = factory.createToken("Token2", "TK2", alice);

        // Get user's tokens
        address[] memory userTokens = factory.getTokensByUser(alice);
        assertEq(userTokens.length, 2);
        assertEq(userTokens[0], token1);
        assertEq(userTokens[1], token2);

        vm.stopPrank();
    }

    function testGetTotalTokenCount() public {
        assertEq(factory.getTotalTokenCount(), 0);

        vm.startPrank(owner);

        // Create tokens
        factory.createToken("Token1", "TK1", address(0));
        assertEq(factory.getTotalTokenCount(), 1);

        factory.createToken("Token2", "TK2", address(0));
        assertEq(factory.getTotalTokenCount(), 2);

        vm.stopPrank();
    }
}