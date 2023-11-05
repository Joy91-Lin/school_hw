pragma solidity ^0.8.17;

import "ERC721A/ERC721A.sol";

contract MyERC721A is ERC721A{

    constructor() ERC721A("MyERC721A standard", "M721A"){
    }
    
    function mint(address to, uint256 quantity) public{
        _mint(to, quantity);
    }
}