// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    event SwapToWETH(address account, uint value);
    event SwapBackToETH(address account, uint value);
    event Receive(address account, uint value);
    event FallBack(address account, uint value, bytes data);

    // 傳送ether時receive會執行並紀錄event log
    receive() external payable { 
        emit Receive(msg.sender, msg.value);
    }
    // 避免有使用者直接向合約傳送ether
    fallback() external payable { 
        emit FallBack(msg.sender, msg.value, msg.data);
        swapToWETH();
    }

    constructor() ERC20("Wrapped Ether", "WETH"){}

    // 將ether轉成Wrapped ether，並發出event log
    function swapToWETH()public payable {
        require(msg.value > 0, "Value must bigger than 0.");
        // 鑄造msg.value數量的新代幣
        _mint(msg.sender, msg.value);
        emit SwapToWETH(msg.sender, msg.value);
    }

    // 將Wrapped Ether轉成ether提取出來，並發出event log
    function swapBackToETH(uint amount) public {
        // 檢查餘額
        uint balance = balanceOf(msg.sender);
        require(balance >= amount, "Insufficient balance.");
        
        // 銷毀amount量的代幣
        _burn(msg.sender, amount);
        (bool s, ) = payable(msg.sender).call{value:amount}("");
        require(s,"Swap back to ETH Failed.");
        emit SwapBackToETH(msg.sender, amount);
    }

}