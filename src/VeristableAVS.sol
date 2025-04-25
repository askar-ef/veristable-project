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

  TokenFactory public factory;

  // token -> underwriter -> amount
  mapping(address => mapping(address => uint128)) public underwritingAmounts;

  // token -> total underwritten amount
  mapping(address => uint128) public totalUnderwriting;

  // token -> total rewards available
  mapping(address => uint128) public totalRewards;

  // token -> underwriter -> unclaimed rewards
  mapping(address => mapping(address => uint128)) public unclaimedRewards;

  // Pause state
  bool public paused;

  // Owner of the contract
  address public owner;

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
   * @notice Function to underwrite tokens
   * @param token Address of the token to underwrite
   * @param amount Amount of tokens to underwrite
   */
  function underwrite(address token, uint128 amount) public whenNotPaused {
    if (!factory.AVSTokens(token)) revert NotRegisteredToken();
    address underwriter = msg.sender;

    // Update rewards before modifying underwriting amounts
    _updateRewards(token, underwriter);

    // Transfer tokens from underwriter to contract
    IERC20(token).transferFrom(underwriter, address(this), amount);

    underwritingAmounts[token][underwriter] += amount;
    totalUnderwriting[token] += amount;
  }

  
  /**
   * @notice Function to withdraw underwritten tokens
   * @param token Address of the token to withdraw
   * @param amount Amount of tokens to withdraw
   */
  function withdraw(address token, uint128 amount) public whenNotPaused {
    address underwriter = msg.sender;

    // Update rewards before modifying underwriting amounts
    _updateRewards(token, underwriter);

    if (underwritingAmounts[token][underwriter] < amount) revert InsufficientBalance();
    underwritingAmounts[token][underwriter] -= amount;
    totalUnderwriting[token] -= amount;

    // Transfer tokens back to the underwriter
    IERC20(token).transfer(underwriter, amount);
  }

  /**
   * @notice Function to claim rewards
   * @param token Address of the token for which rewards are claimed
   */
  function claimRewards(address token) public whenNotPaused {
    address underwriter = msg.sender;

    // Update rewards before claiming
    _updateRewards(token, underwriter);

    uint128 rewardsToClaim = unclaimedRewards[token][underwriter];
    if (rewardsToClaim == 0) revert NoRewardsAvailable();

    unclaimedRewards[token][underwriter] = 0;

    // Transfer rewards to the underwriter
    IERC20(token).transfer(underwriter, rewardsToClaim);
  }

  /**
   * @notice Function to deposit rewards (only callable by owner)
   * @param token Address of the token to deposit rewards
   * @param amount Amount of rewards to deposit
   */
  function depositRewards(address token, uint128 amount) public onlyOwner {
    totalRewards[token] += amount;
    IERC20(token).transferFrom(msg.sender, address(this), amount);
  }

  /**
   * @notice Internal function to update rewards for an underwriter
   * @param token Address of the token
   * @param underwriter Address of the underwriter
   */
  function _updateRewards(address token, address underwriter) internal {
    uint128 totalUnderwritten = totalUnderwriting[token];
    if (totalUnderwritten == 0) return;

    uint128 underwriterAmount = underwritingAmounts[token][underwriter];
    if (underwriterAmount == 0) return;  // Skip if underwriter has no stake

    uint128 newRewards = uint128((uint256(totalRewards[token]) * uint256(underwriterAmount)) / uint256(totalUnderwritten));
    if (newRewards == 0) return;  // Skip if no rewards to claim

    unclaimedRewards[token][underwriter] += newRewards;
    totalRewards[token] -= newRewards;
  }

  /**
   * @notice Function to pause the contract
   */
  function pause() public onlyOwner {
    paused = true;
  }

  /**
   * @notice Function to unpause the contract
   */
  function unpause() public onlyOwner {
    paused = false;
  }

  /**
   * @notice Function to transfer ownership of the contract
   * @param newOwner Address of the new owner
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid address");
    owner = newOwner;
  }
}