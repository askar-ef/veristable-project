// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Token.sol";

contract TokenFactory is Ownable {
    // Mapping to track tokens created by each address
    mapping(address => address[]) public userTokens;
    mapping(address => bool) public AVSTokens; // Mapping to mark valid tokens
    // Array to store all created tokens
    // address[] public allTokens;

    event TokenCreated(address indexed tokenAddress, string name, string symbol, address owner);
    event TokenAddedToAVS(address indexed tokenAddress);
    event TokenRemovedFromAVS(address indexed tokenAddress);

    constructor() Ownable(msg.sender) {
    }
    
    /**
     * @notice Create a new token
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param tokenOwner Address of the token owner (optional, defaults to msg.sender)
     */
    function createToken(
        string memory name,
        string memory symbol,
        address tokenOwner
    ) public returns (address) {

        // If no tokenOwner is provided, default to msg.sender
        address owner = tokenOwner == address(0) ? msg.sender : tokenOwner;

        // Deploy new token
        Token newToken = new Token(name, symbol, owner);

        // Store token address in user's tokens list
        userTokens[owner].push(address(newToken));

        // Mark token as valid in AVSTokens
        AVSTokens[address(newToken)] = true;

        emit TokenCreated(address(newToken), name, symbol, owner);
        emit TokenAddedToAVS(address(newToken));

        return address(newToken);
    }

    /**
     * @notice Add a token to AVSTokens (only callable by owner)
     * @param token Address of the token to add
     */
    function addToAVSTokens(address token) public onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!AVSTokens[token], "Token already in AVS");

        AVSTokens[token] = true;
        emit TokenAddedToAVS(token);
    }

    /**
     * @notice Remove a token from AVSTokens (only callable by owner)
     * @param token Address of the token to remove
     */
    function removeFromAVSTokens(address token) public onlyOwner {
        require(token != address(0), "Invalid token address");
        require(AVSTokens[token], "Token not in AVS");

        AVSTokens[token] = false;
        emit TokenRemovedFromAVS(token);
    }

    /**
     * @notice Get all tokens created by a specific user
     * @param user Address of the user
     * @return List of token addresses
     */
    function getTokensByUser(address user) public view returns (address[] memory) {
        return userTokens[user];
    }

    /**
     * @notice Get total number of tokens created by a user
     * @param user Address of the user
     * @return Total count of tokens
     */
    function getUserTokenCount(address user) public view returns (uint256) {
        return userTokens[user].length;
    }

    /**
     * @notice Get all tokens created through this factory
     * @return List of all token addresses
     */
    // function getAllTokens() public view returns (address[] memory) {
    //     return allTokens;
    // }

    /**
     * @notice Get total number of all tokens
     * @return Total count of all tokens
     */
    // function getTotalTokenCount() public view returns (uint256) {
    //     return allTokens.length;
    // }
}