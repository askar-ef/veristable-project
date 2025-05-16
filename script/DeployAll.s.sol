// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Reserve} from "../src/Reserve.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {VeristableAVS} from "../src/VeristableAVS.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Reserve
        new Reserve();

        // Deploy TokenFactory
        TokenFactory tokenFactory = new TokenFactory();

        // Deploy VeristableAVS with TokenFactory address
        new VeristableAVS(address(tokenFactory));

        vm.stopBroadcast();
    }
}