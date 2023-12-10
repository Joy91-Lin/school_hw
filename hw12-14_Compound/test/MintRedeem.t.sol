// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../script/CompoundPractice.s.sol";

contract MintRedeemTest is Test, CompoundPracticeScript {
    address user1 = makeAddr("user1");
    
    function setUp() public {
        run();
        deal(address(underlying_token), user1, 100 * 10 ** underlying_token.decimals());
    }

    function test_mint_and_redeem() public {
        vm.startPrank(user1);
        // mint
        uint amount = 100 * 10 ** underlying_token.decimals();
        underlying_token.approve(address(delegator), amount);
        uint errcode = delegator.mint(amount);
        assertEq(errcode, 0);
        assertEq(delegator.balanceOf(user1), amount);
        assertEq(underlying_token.balanceOf(user1), 0);

        // redeem
        errcode = delegator.redeem(amount);
        assertEq(errcode, 0);
        assertEq(delegator.balanceOf(user1), 0);
        assertEq(underlying_token.balanceOf(user1), amount);
        vm.stopPrank();
    }
}
