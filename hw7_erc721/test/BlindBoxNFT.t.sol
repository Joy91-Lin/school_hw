// SPDX-License-Identifier: MIX
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {BlindBoxNFT} from "../src/BlindBoxNFT.sol";
import "forge-std/console.sol"; 

contract BlindBoxNFTTest is Test {
    BlindBoxNFT nft;
    address user1;
    function setUp() public {
        nft = new BlindBoxNFT();
        user1 = makeAddr("user1");
    }

    // test totalSupply = 500
    function test_nft_max()public{
        vm.startPrank(user1);
        for(int i = 0;i < 500; i++){
            nft.mint();
        }
        vm.expectRevert("All NFT have been mint.");
        nft.mint();
        vm.stopPrank();
    }

    function test_unBoxing_nft()public{
        vm.startPrank(user1);
        // mint 3 nft and test if its tokenURI is same as blindBoxTokenURI
        string memory blindBoxTokenURI = "ipfs://Qmdie8GoUDNNghRKvovXFMBzhbmdra3V3ndHTsjSS4M34c";
        uint firstID = nft.mint();
        assertEq(blindBoxTokenURI, nft.tokenURI(firstID));
        uint secondID = nft.mint();
        assertEq(blindBoxTokenURI, nft.tokenURI(secondID));
        uint thirdID = nft.mint();
        assertEq(blindBoxTokenURI, nft.tokenURI(thirdID));

        nft.openBox();
        
        string memory cat0_tokenURI = "ipfs://QmPvVd3Vp7oqpPvpdUGPGaosYgAcampfnWpBDzBSWoaPMY/0";
        string memory cat1_tokenURI = "ipfs://QmPvVd3Vp7oqpPvpdUGPGaosYgAcampfnWpBDzBSWoaPMY/1";
        
        // if tokenID is odd,tokenURI is equal to cat1_tokenURI.
        // if tokenID is even,tokenURI is equal to cat0_tokenURI.
        if(firstID % 2 == 1){
            assertEq(cat1_tokenURI, nft.tokenURI(firstID));
        } else{
            assertEq(cat0_tokenURI, nft.tokenURI(firstID));
        }

        if(secondID % 2 == 1){
            assertEq(cat1_tokenURI, nft.tokenURI(secondID));
        } else{
            assertEq(cat0_tokenURI, nft.tokenURI(secondID));
        }

        if(thirdID % 2 == 1){
            assertEq(cat1_tokenURI, nft.tokenURI(thirdID));
        } else{
            assertEq(cat0_tokenURI, nft.tokenURI(thirdID));
        }
        vm.stopPrank();
    }
}