// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Reserve is Ownable {
    // Mapping to store the reserve balance for each token
    mapping(address => uint256) public tokenReserves;

    // Variable to track the last update timestamp globally
    uint256 public lastUpdateTimestamp;

    event ReserveUpdated(address indexed tokenAddress, uint256 newBalance, uint256 timestamp);

    /**
     * @dev Constructor initializes the contract and sets the deployer as the owner.
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Initialize or update the reserve balance for a specific token.
     * Only the owner of the contract can call this function.
     */
    function setReserveBalance(address tokenAddress, uint256 newBalance) external onlyOwner {
        require(newBalance > 0, "New balance must be greater than 0");

        // Update the reserve balance for the token
        tokenReserves[tokenAddress] = newBalance;

        // Update the global last update timestamp
        lastUpdateTimestamp = block.timestamp;

        // Emit an event for transparency
        emit ReserveUpdated(tokenAddress, newBalance, block.timestamp);
    }

    /**
     * @dev Get the reserve balance for a specific token.
     */
    function getReserveBalance(address tokenAddress) external view returns (uint256) {
        return tokenReserves[tokenAddress];
    }

    /**
     * @dev Get the last update timestamp.
     */
    function getLastUpdateTimestamp() external view returns (uint256) {
        return lastUpdateTimestamp;
    }
}