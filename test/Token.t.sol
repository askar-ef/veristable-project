// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    Token public token;
    address public owner;
    address public user;
    address public spender;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        spender = address(0x2);
        token = new Token("Test Token", "TEST", owner);
        token.mint(owner, 1000000 * 1e18);
    }

    function testInitialSetup() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.totalSupply(), 1000000 * 1e18);
        assertEq(token.balanceOf(owner), 1000000 * 1e18);
        assertEq(token.owner(), owner);
        console.log("ea");
    }

    function testMintAsOwner() public {
        uint256 mintAmount = 1000 * 1e18;
        token.mint(user, mintAmount);
        assertEq(token.balanceOf(user), mintAmount);
        assertEq(token.totalSupply(), 1001000 * 1e18);
    }

    function test_RevertWhen_MintAsNonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        token.mint(user, 1000 * 1e18);
    }

    function testBurn() public {
        uint256 burnAmount = 1000 * 1e18;
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(owner);
        
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }

    function test_RevertWhen_BurnAsNonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        token.burn(1000 * 1e18);
    }

    function test_RevertWhen_BurnMoreThanBalance() public {
        uint256 burnAmount = 2000000 * 1e18; // More than total supply
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, owner, 1000000 * 1e18, burnAmount));
        token.burn(burnAmount);
    }

    function testTransfer() public {
        uint256 transferAmount = 100 * 1e18;
        bool success = token.transfer(user, transferAmount);
        assertTrue(success);
        assertEq(token.balanceOf(user), transferAmount);
        assertEq(token.balanceOf(owner), 1000000 * 1e18 - transferAmount);
    }

    function testApproveAndAllowance() public {
        uint256 approveAmount = 500 * 1e18;
        bool success = token.approve(spender, approveAmount);
        assertTrue(success);
        assertEq(token.allowance(owner, spender), approveAmount);
    }

    function testTransferFrom() public {
        uint256 approveAmount = 500 * 1e18;
        uint256 transferAmount = 200 * 1e18;
        
        token.approve(spender, approveAmount);
        
        vm.prank(spender);
        bool success = token.transferFrom(owner, user, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(user), transferAmount);
        assertEq(token.balanceOf(owner), 1000000 * 1e18 - transferAmount);
        assertEq(token.allowance(owner, spender), approveAmount - transferAmount);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        uint256 transferAmount = 2000000 * 1e18; // More than total supply
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, owner, 1000000 * 1e18, transferAmount));
        token.transfer(user, transferAmount);
    }

    function test_RevertWhen_TransferFromInsufficientAllowance() public {
        uint256 approveAmount = 100 * 1e18;
        uint256 transferAmount = 200 * 1e18;
        
        token.approve(spender, approveAmount);
        
        vm.prank(spender);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, approveAmount, transferAmount));
        token.transferFrom(owner, user, transferAmount);
    }
}