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

        function setUp() public {
        // Deploy TokenFactory and VeristableAVS
        factory = new TokenFactory();
        avs = new VeristableAVS(address(factory));

        // Create a registered token
        token = factory.createToken("Test Token", "TEST", address(this));
        tokenContract = Token(token);
        
        // Mint tokens untuk testing
        tokenContract.mint(address(this), 1000e18);
    }

    function test_underwrite() public {
        console.log("Balance before underwrite: ", tokenContract.balanceOf(address(this)));
        console.log("Total underwriting amount:", avs.underwritingAmounts(token, address(this)));
        // Approve AVS to spend tokens
        tokenContract.approve(address(avs), 100e18);
        // Underwrite tokens
        avs.underwrite(token, 100e18);
        console.log("Balance after underwrite: ",tokenContract.balanceOf(address(this)));
        console.log("Total underwriting amount:", avs.underwritingAmounts(token, address(this)));
        // Check underwriting amounts
        assertEq(avs.underwritingAmounts(token, address(this)), 100e18);
        assertEq(avs.totalUnderwriting(token), 100e18);
    }

    function test_underwriteMultiple() public {
        // Approve AVS to spend tokens
        tokenContract.approve(address(avs), 150e18);

        // Underwrite tokens multiple times
        avs.underwrite(token, 100e18);
        avs.underwrite(token, 50e18);

        // Check underwriting amounts
        assertEq(avs.underwritingAmounts(token, address(this)), 150e18);
        assertEq(avs.totalUnderwriting(token), 150e18);
    }

    function test_withdraw() public {
        // Approve AVS to spend tokens
        tokenContract.approve(address(avs), 100e18);

        // Underwrite tokens
        avs.underwrite(token, 100e18);

        // Withdraw tokens
        avs.withdraw(token, 50e18);

        // Check underwriting amounts and balance
        assertEq(avs.underwritingAmounts(token, address(this)), 50e18);
        assertEq(avs.totalUnderwriting(token), 50e18);
        assertEq(tokenContract.balanceOf(address(this)), 950e18); // 1000 - 100 + 50
    }

    function test_RevertWhen_WithdrawInsufficientBalance() public {
        // Approve AVS to spend tokens
        tokenContract.approve(address(avs), 100e18);

        // Underwrite tokens
        avs.underwrite(token, 100e18);

        // Attempt to withdraw more than underwritten amount
        vm.expectRevert(VeristableAVS.InsufficientBalance.selector);
        avs.withdraw(token, 200e18);
    }

    function test_depositRewards() public {
        // Mint additional tokens for rewards
        console.log("Token supply:", tokenContract.totalSupply());
        tokenContract.mint(address(this), 200e18);
        tokenContract.approve(address(avs), 200e18);
        
        console.log("Token supply:", tokenContract.totalSupply());

        // Deposit rewards as owner
        vm.prank(address(this)); // Simulate owner
        avs.depositRewards(token, 100e18);

        console.log("Total rewards:", avs.totalRewards(token)); // Add this line for debugging
        console.log("Unclaimed rewards:", avs.unclaimedRewards(token, address(this))); // Add this line for debugging
        console.log("Underwriting amount:", avs.underwritingAmounts(token, address(this))); // Add this line for debugging
        console.log("Balance:", tokenContract.balanceOf(address(this))); // Add this line for debugging

        // Check total rewards
        assertEq(avs.totalRewards(token), 100e18);
    }

    function test_claimRewards() public {
        // Approve AVS to spend tokens
        tokenContract.approve(address(avs), 100e18);

        // Underwrite tokens
        avs.underwrite(token, 100e18);

        // Deposit rewards
        tokenContract.mint(address(this), 100e18);
        tokenContract.approve(address(avs), 100e18);
        vm.prank(address(this)); // Simulate owner
        avs.depositRewards(token, 100e18);

        // Claim rewards
        avs.claimRewards(token);

        // Check unclaimed rewards and balance
        assertEq(avs.unclaimedRewards(token, address(this)), 0);
        assertEq(tokenContract.balanceOf(address(this)), 1000e18); // 900 + 100 rewards
    }

    function test_RevertWhen_ClaimNoRewardsAvailable() public {
        // Attempt to claim rewards without depositing any
        vm.expectRevert(VeristableAVS.NoRewardsAvailable.selector);
        avs.claimRewards(token);
    }

    function test_RevertWhen_UnderwritingUnregisteredToken() public {
        // Create an unregistered token
        Token unregisteredToken = new Token("Unregistered", "UNREG", address(this));
        // cek lagi
        tokenContract.mint(address(unregisteredToken), 100e18);

        // Attempt to underwrite unregistered token
        vm.expectRevert(VeristableAVS.NotRegisteredToken.selector);
        avs.underwrite(address(unregisteredToken), 100e18);
    }

    function test_pauseAndUnpause() public {
        // Pause the contract
        avs.pause();

        // Attempt to underwrite while paused
        vm.expectRevert(VeristableAVS.ContractPaused.selector);
        avs.underwrite(token, 100e18);

        // Unpause the contract
        avs.unpause();

        // Underwrite tokens after unpausing
        tokenContract.approve(address(avs), 100e18);
        avs.underwrite(token, 100e18);

        // Check underwriting amounts
        assertEq(avs.underwritingAmounts(token, address(this)), 100e18);
    }

    function test_transferOwnership() public {
        // Transfer ownership to a new address
        address newOwner = address(0x12345);
        avs.transferOwnership(newOwner);

        // Check new owner
        assertEq(avs.owner(), newOwner);
    }
}