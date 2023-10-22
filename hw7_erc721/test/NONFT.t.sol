// SPDX-License-Identifier: MIX
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {NONFT} from "../src/NONFT.sol";
import {TriggerNFT} from "../src/NONFT.sol";
import {NFTReceiver} from "../src/NONFT.sol";
import "forge-std/console.sol"; 

contract NONFTTest is Test {

    TriggerNFT public triggerNFT;
    NONFT public noNFT;
    NFTReceiver public nftReceiver;
    Account user1;

    function setUp() public {
        triggerNFT = new TriggerNFT();
        noNFT = new NONFT();
        nftReceiver = new NFTReceiver(address(noNFT));
        user1 = makeAccount("user1");
    }

    function test_transferNFT_and_get_poopNFT_back() public{
        vm.startPrank(user1.addr);
        // check user1 do not have any poop nft
        assertEq(noNFT.balanceOf(user1.addr), 0);

        // mint 1 trigger NFT to user1
        triggerNFT.mint(user1.addr, 0);
        assertEq(triggerNFT.ownerOf(0), user1.addr);

        // send trigger nft to nftReceiver address
        triggerNFT.safeTransferFrom(user1.addr, address(nftReceiver), 0);

        // check user1 still have trigger nft
        assertEq(triggerNFT.ownerOf(0), user1.addr);
        
        // check user1 get poop nft
        assertEq(nftReceiver.balanceOf(user1.addr), 1);
        
        vm.stopPrank();
    }

}