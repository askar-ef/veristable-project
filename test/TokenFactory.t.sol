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
        vm.startPrank(alice);

        // Create a token with default owner (msg.sender)
        address tokenAddress = factory.createToken("My Token", "MTK", address(0));
        Token newToken = Token(tokenAddress);
        newToken.mint(bob, 1_000_000 * 1e18); // Mint 1 million tokens to the contract owner for testing purpos

        // Verify token properties
        assertEq(newToken.name(), "My Token");
        assertEq(newToken.symbol(), "MTK");
        assertEq(newToken.totalSupply(), 1_000_000 * 1e18);
        // assertEq(newToken.balanceOf(owner), 1_000_000 * 1e18);
        // assertEq(newToken.owner(), owner);
        console.log('Yang punya token:', newToken.owner());
        console.log('Yang buat token', address(alice));
        console.log('Yang dikasih token:', owner);
        console.log('address ini:', address(this));


        // Verify AVSTokens mapping
        assertTrue(factory.AVSTokens(tokenAddress));

        // Verify token tracking
        // address[] memory userTokens = factory.getTokensByUser(owner);
        // assertEq(userTokens.length, 1);
        // assertEq(userTokens[0], tokenAddress);
        // assertEq(factory.getUserTokenCount(owner), 1);

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
        // address[] memory allTokens = factory.getAllTokens();
        // for (uint i = 0; i < allTokens.length; i++) {
        //     console.log(allTokens[i]);
        // }
        // assertEq(allTokens.length, 2);
        // assertEq(allTokens[0], token1Address);
        // assertEq(allTokens[1], token2Address);

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

    function testAllAVSTokensTracking() public {
        vm.startPrank(owner);

        // Buat beberapa token
        address token1 = factory.createToken("Token1", "TK1", alice);
        address token2 = factory.createToken("Token2", "TK2", bob);
        
        // Verifikasi token ada di mapping AVSTokens
        assertTrue(factory.AVSTokens(token1));
        assertTrue(factory.AVSTokens(token2));

        // Hapus token dari AVS dan verifikasi
        factory.removeFromAVSTokens(token1);
        assertTrue(!factory.AVSTokens(token1));
        assertTrue(factory.AVSTokens(token2));

        // Tambahkan kembali token ke AVS
        factory.addToAVSTokens(token1);
        assertTrue(factory.AVSTokens(token1));
        assertTrue(factory.AVSTokens(token2));

        vm.stopPrank();
    }

    function testAllTokensAndAVSTokensSync() public {
        vm.startPrank(owner);

        // Buat token dan verifikasi keberadaannya
        address token1 = factory.createToken("Token1", "TK1", alice);
        // address token2 = factory.createToken("Token1", "TK1", alice);
        // address token3 = factory.createToken("Token1", "TK1", alice);
        // address token4 = factory.createToken("Token1", "TK1", alice);
        
        // Verifikasi status AVS
        assertTrue(factory.AVSTokens(token1));

        // Verifikasi token tracking untuk alice
        address[] memory userTokens = factory.getTokensByUser(alice);
        console.log(userTokens.length);
        // Print setiap address token
        for(uint i = 0; i < userTokens.length; i++) {
            console.log("Token", i + 1, ":", userTokens[i]);
        }

        vm.stopPrank();
    }
}