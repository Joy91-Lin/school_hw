pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/SimpleSwap.sol";
import { TestERC20 } from "../../../contracts/test/TestERC20.sol";

contract MyScript is Script {
    function run() external{
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY"); // 取得.env檔案中的PRIVATE_KEY
        vm.startBroadcast(userPrivateKey);
        TestERC20 tokenB = new TestERC20("token B", "TKB");
        TestERC20 tokenA = new TestERC20("token A", "TKA");

        SimpleSwap simpleSwap = new SimpleSwap(address(tokenA), address(tokenB));
        vm.stopBroadcast();
    }
}