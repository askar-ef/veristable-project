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
        address tokenFactoryAddress = 0x5418fc891317C20f923ccB431d9B040D14987bD8; // Ganti dengan alamat TokenFactory yang sudah di-deploy
        new VeristableAVS(tokenFactoryAddress);
        
        vm.stopBroadcast();
    }
}