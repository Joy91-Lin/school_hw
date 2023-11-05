// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {MyERC721A} from "../src/MyERC721a.sol";

contract MyERC721ATest is Test {
    MyERC721A public myERC721A;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        myERC721A = new MyERC721A();
    }

    function test_erc721a_Mint_1() public {
        myERC721A.mint(user1, 1);
        assertEq(myERC721A.balanceOf(user1), 1);
    }

    function test_erc721a_BatchMint() public {
        myERC721A.mint(user1, 10);
        assertEq(myERC721A.balanceOf(user1), 10);
    }

    function test_erc721a_transfer() public{
        myERC721A.mint(user1, 1);
        vm.prank(user1);
        myERC721A.transferFrom(user1, user2, 0);
        assertEq(myERC721A.balanceOf(user1), 0);
        assertEq(myERC721A.balanceOf(user2), 1);
    }

    function test_erc721a_approve() public{
        myERC721A.mint(user1, 1);
        address operator = makeAddr("operator");
        vm.prank(user1);
        myERC721A.approve(operator, 0);

        vm.prank(operator);
        myERC721A.transferFrom(user1, user2, 0);
        
        assertEq(myERC721A.balanceOf(user1), 0);
        assertEq(myERC721A.balanceOf(user2), 1);
    }

    function test_erc721a_sequence_ID_transfer_middle() public{
        myERC721A.mint(user1, 5);
        vm.prank(user1);
        myERC721A.transferFrom(user1, user2, 2);
        assertEq(myERC721A.balanceOf(user1), 4);
        assertEq(myERC721A.balanceOf(user2), 1);
    }

    function test_erc721a_sequence_ID_transfer_last() public{
        myERC721A.mint(user1, 5);
        vm.prank(user1);
        myERC721A.transferFrom(user1, user2, 4);
        assertEq(myERC721A.balanceOf(user1), 4);
        assertEq(myERC721A.balanceOf(user2), 1);
    }
}
