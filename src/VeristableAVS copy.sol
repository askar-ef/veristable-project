// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenFactory} from "./TokenFactory.sol";

contract VeristableAVS {

  error NotRegisteredToken();

  TokenFactory public factory;

  // token -> underwriter -> amount
  mapping(address => mapping(address => uint256)) public underwritingAmounts;

  constructor(address _factory) {
    factory = TokenFactory(_factory);
  }

   function underwrite(address token,uint256 amount) public {
      if(!factory.AVSTokens(token)) revert NotRegisteredToken();
      address underwriter = msg.sender;
      underwritingAmounts[token][underwriter] += amount;
   }

}
