// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/Token.sol";
import "./VeristableAVS.sol";

contract TokenFactoryx {
    // Mapping to track tokens created by each address
    mapping(address => address[]) public userTokens;
    mapping(address => bool) public AVSTokens;
    // Array to store all created tokens
    address[] public allTokens;
    
    event TokenCreated(address indexed tokenAddress, string name, string symbol, address owner);

    function createToken(string memory name, string memory symbol,uint256 initialSupply) public returns (address) {
        require(initialSupply > 0, "Initial supply must be greater than 0");
        Token newToken = new Token(name, symbol, initialSupply, msg.sender);

        
        // Store token address in user's tokens list
        userTokens[msg.sender].push(address(newToken));
        allTokens.push(address(newToken));
        
        emit TokenCreated(address(newToken), name, symbol, msg.sender);

        AVSTokens[address(newToken)] = true;

        return address(newToken);
    }

    // Get all tokens created by a specific user
    function getTokensByUser(address user) public view returns (address[] memory) {
        return userTokens[user];
    }

    // Get total number of tokens created by a user
    function getUserTokenCount(address user) public view returns (uint256) {
        return userTokens[user].length;
    }

    // Get all tokens created through this factory
    function getAllTokens() public view returns (address[] memory) {
        return allTokens;
    }

    // Get total number of all tokens
    function getTotalTokenCount() public view returns (uint256) {
        return allTokens.length;
    }
}