// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VeristableAVS} from "../src/VeristableAVS.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {console} from "forge-std/console.sol";

contract VeristableAVSTest is Test {
    VeristableAVS public avs;
    TokenFactory public factory;
    address public token;
    Token public tokenContract;

    function setUp() public {
        factory = new TokenFactory();
        avs = new VeristableAVS(address(factory));
        token = factory.createToken("Test Token", "TEST", 1000e18, msg.sender);
        tokenContract = Token(token);
    }

    function test_underwrite() public {
        avs.underwrite(token, 100e18);
        console.log(token);
        // check token name
        console.log(tokenContract.name());
        console.log(factory.AVSTokens(token));
        assertEq(avs.underwritingAmounts(token, address(this)), 100e18);
    }

    function test_underwriteMultiple() public {
        avs.underwrite(token, 100e18);
        avs.underwrite(token, 50e18);
        console.log(avs.underwritingAmounts(token, address(this)));
        assertEq(avs.underwritingAmounts(token, address(this)), 150e18);
    }

    function test_RevertWhen_UnderwritingUnregisteredToken() public {
        Token unregisteredToken = new Token("Unregistered", "UNREG", 1000e18, address(this));
        vm.expectRevert(VeristableAVS.NotRegisteredToken.selector);
        avs.underwrite(address(unregisteredToken), 100e18);
    }

    function test_factoryAddress() public view {
        assertEq(address(avs.factory()), address(factory));
    }
}