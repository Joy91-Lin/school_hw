pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {MyERC721} from "../src/MyERC721.sol";

contract MyERC721Test is Test{
    MyERC721 public myERC721;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        myERC721 = new MyERC721();
    }

    function test_erc721_Mint_1() public {
        myERC721.mint(user1, 0);
        assertEq(myERC721.balanceOf(user1), 1);
    }

    function test_erc721_BatchMint() public {
        for(uint i = 0; i < 10; i++){
            myERC721.mint(user1, i);
        }
        assertEq(myERC721.balanceOf(user1), 10);
    }

    function test_erc721_transfer() public{
        myERC721.mint(user1, 0);
        vm.prank(user1);
        myERC721.transferFrom(user1, user2, 0);
        assertEq(myERC721.balanceOf(user1), 0);
        assertEq(myERC721.balanceOf(user2), 1);
    }

    function test_erc721_approve() public{
        myERC721.mint(user1, 0);
        address operator = makeAddr("operator");
        vm.prank(user1);
        myERC721.approve(operator, 0);

        vm.prank(operator);
        myERC721.transferFrom(user1, user2, 0);
        
        assertEq(myERC721.balanceOf(user1), 0);
        assertEq(myERC721.balanceOf(user2), 1);
    }
}