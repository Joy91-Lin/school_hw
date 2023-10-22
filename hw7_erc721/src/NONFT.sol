// SPDX-License-Identifier: MIX
pragma solidity ^0.8.17;

import "@openzeppelin/ERC721/ERC721.sol";
import "@openzeppelin/ERC721/IERC721.sol";
import "@openzeppelin/ERC721/IERC721Receiver.sol";

contract TriggerNFT is ERC721{
    constructor()ERC721("Trigger NFT","TNFT"){}

     function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

}

contract NONFT is ERC721{ 
    uint mintCounter;
    constructor() ERC721("Don't send NFT to me","NONFT"){}

    // mint NFT tokens
    function mint(address to) internal {
        _mint(to, mintCounter);
        mintCounter++;
    }

    // let all NFT token be the same resource
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return "ipfs://Qmdie8GoUDNNghRKvovXFMBzhbmdra3V3ndHTsjSS4M34c";
    }
}

contract NFTReceiver is IERC721Receiver, NONFT{
    address noNFTAddr;

    constructor (address addr){
        noNFTAddr = addr;
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        // check if sender is NONFT
        if(msg.sender != noNFTAddr){
            // mint a NONFT to from address
            mint(from);
            
            // transfer trigger nft back
            IERC721(msg.sender).safeTransferFrom(address(this), from, tokenId, data);
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}