// SPDX-License-Identifier: MIX
pragma solidity ^0.8.17;

import "@openzeppelin/ERC721/ERC721.sol";
import "@openzeppelin/ERC721/IERC721.sol";
import "@openzeppelin/ERC721/IERC721Receiver.sol";


contract BlindBoxNFT is ERC721{
    string constant blindBoxTokenURI = "ipfs://Qmdie8GoUDNNghRKvovXFMBzhbmdra3V3ndHTsjSS4M34c";
    bool reveal;
    uint immutable totalSupply;
    uint counter;


    constructor () ERC721("Blind Box NFT","BBNFT"){
        totalSupply = 500;
    }

    function mint()public returns (uint tokenID) {
        require(counter < totalSupply, "All NFT have been mint.");
        tokenID = counter;
        _safeMint(msg.sender, tokenID);
        counter++;
        return tokenID;
    }

    function openBox() public{
        reveal = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        if (!reveal){
            return blindBoxTokenURI;
        }

        string memory baseURI = _baseURI();
        string memory cat_img_id = (tokenId % 2) == 1 ? "1": "0";
        return bytes(baseURI).length > 0 ? string.concat(baseURI, cat_img_id) : "";
    }

    
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmPvVd3Vp7oqpPvpdUGPGaosYgAcampfnWpBDzBSWoaPMY/";
    }
}