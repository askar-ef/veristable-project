// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenFactory.sol";
import "../src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;
    address public alice;
    address public bob;

    event TokenCreated(address indexed tokenAddress, string name, string symbol, address owner);

    function setUp() public {
        factory = new TokenFactory();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    function testCreateToken() public {
        vm.startPrank(alice);
        
        address tokenAddress = factory.createToken("My Token", "MTK", 1000000 * 1e18);
        Token newToken = Token(tokenAddress);
        
        // Verify token properties
        assertEq(newToken.name(), "My Token");
        assertEq(newToken.symbol(), "MTK");
        assertEq(newToken.totalSupply(), 1000000 * 1e18);
        assertEq(newToken.balanceOf(alice), 1000000 * 1e18);
        assertEq(newToken.owner(), alice);
        
        // Verify token tracking
        address[] memory userTokens = factory.getTokensByUser(alice);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], tokenAddress);
        assertEq(factory.getUserTokenCount(alice), 1);
        
        vm.stopPrank();
    }

    function testMultipleTokenCreation() public {
        // alice creates a token
        vm.prank(alice);
        address token1Address = factory.createToken("Token1", "TK1", 1000000 * 1e18);
        Token token1 = Token(token1Address);
        
        // bob creates a different token
        vm.prank(bob);
        address token2Address = factory.createToken("Token2", "TK2", 2000000 * 1e18);
        Token token2 = Token(token2Address);
        
        // Verify tokens are different and have correct properties
        assertTrue(token1Address != token2Address);
        assertEq(token1.owner(), alice);
        assertEq(token2.owner(), bob);
        assertEq(token1.balanceOf(alice), 1000000 * 1e18);
        assertEq(token2.balanceOf(bob), 2000000 * 1e18);

        // Verify token tracking for both users
        assertEq(factory.getUserTokenCount(alice), 1);
        assertEq(factory.getUserTokenCount(bob), 1);
        
        // Verify all tokens array
        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 2);
        assertEq(allTokens[0], token1Address);
        assertEq(allTokens[1], token2Address);
    }

    function testTokenFunctionality() public {
        // Create token
        vm.prank(alice);
        address tokenAddress = factory.createToken("Test", "TST", 1000000 * 1e18);
        Token token = Token(tokenAddress);
        
        // Test mint
        vm.prank(alice);
        token.mint(bob, 1000 * 1e18);
        assertEq(token.balanceOf(bob), 1000 * 1e18);
        
        // Test burn
        vm.prank(alice);
        token.burn(1000 * 1e18);
        assertEq(token.balanceOf(alice), 999000 * 1e18);
        
        // Test transfer
        vm.prank(alice);
        token.transfer(bob, 1000 * 1e18);
        assertEq(token.balanceOf(bob), 2000 * 1e18);
    }

    function test_RevertWhen_ZeroInitialSupply() public {
        vm.prank(alice);
        vm.expectRevert("Initial supply must be greater than 0");
        factory.createToken("Zero Token", "ZERO", 0);
    }

    function testCreateTokenWithMaxSupply() public {
        uint256 maxSupply = type(uint256).max;
        vm.prank(alice);
        address tokenAddress = factory.createToken("Max Token", "MAX", maxSupply);
        Token token = Token(tokenAddress);
        assertEq(token.totalSupply(), maxSupply);
    }

    function testGetTokensByUser() public {
        // Create multiple tokens for alice
        vm.startPrank(alice);
        address token1 = factory.createToken("Token1", "TK1", 1000000 * 1e18);
        address token2 = factory.createToken("Token2", "TK2", 2000000 * 1e18);
        vm.stopPrank();

        // Get user's tokens
        address[] memory userTokens = factory.getTokensByUser(alice);
        assertEq(userTokens.length, 2);
        assertEq(userTokens[0], token1);
        assertEq(userTokens[1], token2);
    }

    function testGetTotalTokenCount() public {
        assertEq(factory.getTotalTokenCount(), 0);

        vm.prank(alice);
        factory.createToken("Token1", "TK1", 1000000 * 1e18);
        assertEq(factory.getTotalTokenCount(), 1);

        vm.prank(bob);
        factory.createToken("Token2", "TK2", 2000000 * 1e18);
        assertEq(factory.getTotalTokenCount(), 2);
    }
}