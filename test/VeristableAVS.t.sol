// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VeristableAVS} from "../src/VeristableAVS.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {console} from "forge-std/console.sol";

contract VeristableAVSTest is Test {
    VeristableAVS public avs;
    TokenFactory public factory;
    address public token;
    Token public tokenContract;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        // Deploy contracts
        factory = new TokenFactory();
        avs = new VeristableAVS(address(factory));

        // Create test token
        token = factory.createToken("Test Token", "TEST", address(this));
        tokenContract = Token(token);

        // Give ETH to test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_StakeForToken() public {
        vm.prank(alice);
        avs.stakeForToken{value: 1 ether}(token);
        
        assertEq(avs.tokenStakes(token, alice), 1 ether);
        assertEq(avs.totalTokenStakes(token), 1 ether);
    }

    function test_RevertWhen_StakeInsufficientETH() public {
        vm.prank(alice);
        vm.expectRevert(VeristableAVS.InsufficientETH.selector);
        avs.stakeForToken{value: 0.009 ether}(token);
    }

    function test_RevertWhen_StakeUnregisteredToken() public {
        address fakeToken = makeAddr("fakeToken");
        vm.prank(alice);
        vm.expectRevert(VeristableAVS.NotRegisteredToken.selector);
        avs.stakeForToken{value: 1 ether}(fakeToken);
    }

    function test_UnstakeFromToken() public {
        // Setup initial stake
        vm.prank(alice);
        avs.stakeForToken{value: 1 ether}(token);
        
        // Warp time past lock period
        vm.warp(block.timestamp + 25 hours);
        
        uint256 initialBalance = alice.balance;
        
        vm.prank(alice);
        avs.unstakeFromToken(token, 0.5 ether);
        
        assertEq(avs.tokenStakes(token, alice), 0.5 ether);
        assertEq(avs.totalTokenStakes(token), 0.5 ether);
        assertEq(alice.balance, initialBalance + 0.5 ether);
    }

    function test_RevertWhen_UnstakeDuringLock() public {
        vm.prank(alice);
        avs.stakeForToken{value: 1 ether}(token);
        
        vm.prank(alice);
        vm.expectRevert(VeristableAVS.StakingLocked.selector);
        avs.unstakeFromToken(token, 0.5 ether);
    }

    function test_DistributeAndClaimRewards() public {
        // Setup stakes
        vm.prank(alice);
        avs.stakeForToken{value: 1 ether}(token);
        
        vm.prank(bob);
        avs.stakeForToken{value: 1 ether}(token);
        
        // Distribute rewards
        avs.distributeTokenRewards{value: 2 ether}(token);
        
        uint256 initialBalance = alice.balance;
        
        // Claim rewards
        vm.prank(alice);
        avs.claimTokenRewards(token);
        
        assertEq(alice.balance, initialBalance + 1 ether);
    }

    function test_RevertWhen_ClaimNoRewards() public {
        vm.prank(alice);
        vm.expectRevert(VeristableAVS.NoRewardsAvailable.selector);
        avs.claimTokenRewards(token);
    }

    function test_PauseAndUnpause() public {
        avs.pause();
        assertTrue(avs.paused());
        
        vm.prank(alice);
        vm.expectRevert(VeristableAVS.ContractPaused.selector);
        avs.stakeForToken{value: 1 ether}(token);
        
        avs.unpause();
        assertFalse(avs.paused());
        
        vm.prank(alice);
        avs.stakeForToken{value: 1 ether}(token);
        assertEq(avs.tokenStakes(token, alice), 1 ether);
    }

    function test_TransferOwnership() public {
        avs.transferOwnership(alice);
        assertEq(avs.owner(), alice);
        
        vm.prank(alice);
        avs.pause();
        assertTrue(avs.paused());
    }

    function test_RevertWhen_NonOwnerAction() public {
        vm.prank(alice);
        vm.expectRevert(VeristableAVS.NotOwner.selector);
        avs.pause();
    }

    receive() external payable {}
}