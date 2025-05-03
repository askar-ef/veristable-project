// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenFactory} from "./TokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VeristableAVS {
    error NotRegisteredToken();
    error InsufficientBalance();
    error NotOwner();
    error ContractPaused();
    error NoRewardsAvailable();
    error InsufficientETH();
    error WithdrawFailed();
    error StakingLocked();

    TokenFactory public factory;

    // token -> staker -> ETH amount
    mapping(address => mapping(address => uint256)) public tokenStakes;
    
    // token -> total ETH staked
    mapping(address => uint256) public totalTokenStakes;
    
    // Minimum ETH required per token stake
    uint256 public constant MIN_TOKEN_STAKE = 0.01 ether;

    // token -> rewards pool
    mapping(address => uint256) public tokenRewardsPools;

    // token -> staker -> pending rewards
    mapping(address => mapping(address => uint256)) public pendingTokenRewards;

    // token -> staker -> last stake timestamp
    mapping(address => mapping(address => uint256)) public lastStakeTime;

    // Locking period for stakes (1 hours)
    uint256 public constant LOCK_PERIOD = 2 minutes;

    // Pause state
    bool public paused;

    // Owner of the contract
    address public owner;

    event TokenStaked(address indexed token, address indexed staker, uint256 amount);
    event TokenUnstaked(address indexed token, address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed token, address indexed claimer, uint256 amount);
    event RewardsDistributed(address indexed token, uint256 amount);

    constructor(address _factory) {
        factory = TokenFactory(_factory);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    /**
     * @notice Function to stake ETH for specific token
     * @param token Address of the token to stake for
     */
    function stakeForToken(address token) external payable whenNotPaused {
        if (!factory.AVSTokens(token)) revert NotRegisteredToken();
        if (msg.value < MIN_TOKEN_STAKE) revert InsufficientETH();
        
        _updateRewards(token, msg.sender);
        
        tokenStakes[token][msg.sender] += msg.value;
        totalTokenStakes[token] += msg.value;
        lastStakeTime[token][msg.sender] = block.timestamp;
        
        emit TokenStaked(token, msg.sender, msg.value);
    }

    /**
     * @notice Function to unstake ETH from specific token
     * @param token Address of the token
     * @param amount Amount of ETH to unstake
     */
    function unstakeFromToken(address token, uint256 amount) external whenNotPaused {
        if (tokenStakes[token][msg.sender] < amount) revert InsufficientBalance();
        if (block.timestamp < lastStakeTime[token][msg.sender] + LOCK_PERIOD) revert StakingLocked();
        
        _updateRewards(token, msg.sender);
        
        tokenStakes[token][msg.sender] -= amount;
        totalTokenStakes[token] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert WithdrawFailed();
        
        emit TokenUnstaked(token, msg.sender, amount);
    }

    /**
     * @notice Function to claim rewards for specific token
     * @param token Address of the token
     */
    function claimTokenRewards(address token) external whenNotPaused {
        _updateRewards(token, msg.sender);
        
        uint256 rewards = pendingTokenRewards[token][msg.sender];
        if (rewards == 0) revert NoRewardsAvailable();
        
        pendingTokenRewards[token][msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: rewards}("");
        if (!success) revert WithdrawFailed();
        
        emit RewardsClaimed(token, msg.sender, rewards);
    }

    /**
     * @notice Internal function to update rewards for a token staker
     */
    function _updateRewards(address token, address staker) internal {
        uint256 totalStaked = totalTokenStakes[token];
        if (totalStaked == 0) return;
        
        uint256 stakerAmount = tokenStakes[token][staker];
        if (stakerAmount == 0) return;

        uint256 rewardsPool = tokenRewardsPools[token];
        uint256 newRewards = (rewardsPool * stakerAmount) / totalStaked;
        if (newRewards == 0) return;

        pendingTokenRewards[token][staker] += newRewards;
        tokenRewardsPools[token] -= newRewards;
    }

    /**
     * @notice Function to distribute rewards for specific token
     * @param token Address of the token
     */
    function distributeTokenRewards(address token) external payable onlyOwner {
        tokenRewardsPools[token] += msg.value;
        emit RewardsDistributed(token, msg.value);
    }

    /**
     * @notice Function to pause the contract
     */
    function pause() external onlyOwner {
        paused = true;
    }

    /**
     * @notice Function to unpause the contract
     */
    function unpause() external onlyOwner {
        paused = false;
    }

    /**
     * @notice Function to transfer ownership of the contract
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    receive() external payable {}
    fallback() external payable {}
}