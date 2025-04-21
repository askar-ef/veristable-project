// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Reserve.sol";

contract ReserveTest is Test {
    Reserve reserve;
    address owner = address(0x1);
    address nonOwner = address(0x2);
    address tokenAddress = address(0x123);

    event ReserveUpdated(address indexed tokenAddress, uint256 newBalance, uint256 timestamp);

    function setUp() public {
        vm.prank(owner);
        reserve = new Reserve();
    }

    function test_InitialState() public view{
        assertEq(reserve.owner(), owner);
        assertEq(reserve.getReserveBalance(tokenAddress), 0);
        assertEq(reserve.getLastUpdateTimestamp(), 0);
    }

    function test_SetReserveBalance_Success() public {
        uint256 newBalance = 1000 ether;
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit ReserveUpdated(tokenAddress, newBalance, block.timestamp);
        reserve.setReserveBalance(tokenAddress, newBalance);

        assertEq(reserve.getReserveBalance(tokenAddress), newBalance);

        assertEq(reserve.getLastUpdateTimestamp(), block.timestamp);
    }

    function test_SetReserveBalance_NonOwner_Reverts() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        reserve.setReserveBalance(tokenAddress, 1000 ether);
    }

    function test_SetReserveBalance_ZeroBalance_Reverts() public {
        vm.prank(owner);
        vm.expectRevert("New balance must be greater than 0");
        reserve.setReserveBalance(tokenAddress, 0);
    }

    function test_GetReserveBalance() public {
        vm.prank(owner);
        reserve.setReserveBalance(tokenAddress, 500 ether);
        assertEq(reserve.getReserveBalance(tokenAddress), 500 ether);
    }

    function test_GetLastUpdateTimestamp() public {
        vm.prank(owner);
        reserve.setReserveBalance(tokenAddress, 500 ether);

        assertEq(reserve.getLastUpdateTimestamp(), block.timestamp);
    }
}