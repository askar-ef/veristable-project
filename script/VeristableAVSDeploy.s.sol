// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {VeristableAVS} from "../src/VeristableAVS.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

contract VeristableAVSDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy VeristableAVS dengan alamat TokenFactory sebagai parameter
        // Pastikan TokenFactory sudah di-deploy terlebih dahulu
        address tokenFactoryAddress = 0x9C34c7d588C2db8f5f4626C5e8C6E51cffFDF9e1; // Ganti dengan alamat TokenFactory yang sudah di-deploy
        new VeristableAVS(tokenFactoryAddress);
        
        vm.stopBroadcast();
    }
}