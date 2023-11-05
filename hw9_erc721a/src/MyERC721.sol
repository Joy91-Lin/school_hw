pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MyERC721 is  ERC721Enumerable{
    constructor() ERC721("MyERC721 standard", "M721"){
    }

    function mint(address to, uint256 tokenId) public{
        _mint(to, tokenId);
    }

}