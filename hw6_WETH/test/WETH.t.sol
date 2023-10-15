// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {WETH} from "../src/WETH.sol";
import "forge-std/console.sol"; 

contract WETHTest is Test{
    event SwapToWETH(address account, uint value);
    event SwapBackToETH(address account, uint value);

    WETH public weth;
    address user1;
    function setUp() public{
        user1 = makeAddr("user1");
        weth = new WETH();
    }

    /**
    測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
    測項 2: deposit 應該將 msg.value 的 ether 轉入合約
    測項 3: deposit 應該要 emit Deposit event
     */    
    function testSwapToWETH() public{
        vm.startPrank(user1);
        uint depositAmount = 1 ether;
        deal(user1, depositAmount);

        // test3
        vm.expectEmit(true, false, false, true);
        emit SwapToWETH(user1, depositAmount);
        
        vm.expectCall(address(weth), 
                    depositAmount,
                    abi.encodeWithSelector(weth.swapToWETH.selector));
        weth.swapToWETH{value:depositAmount}();

        // test1
        uint wethBalace = weth.balanceOf(user1);
        assertEq(wethBalace, depositAmount);

        // test2
        uint contractBalance = address(weth).balance;
        console.log(contractBalance);
        assertEq(contractBalance, depositAmount);
        vm.stopPrank();
    }
    /**
    測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
    測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
    測項 6: withdraw 應該要 emit Withdraw event
     */
    function testSwapBackToETH() public{
        // set user1 1 ether and swap it to weth
        vm.startPrank(user1);
        deal(user1, 1 ether);
        weth.swapToWETH{value:1 ether}();

        // start swap back test
        // test6
        uint withdrawAmount = 1 ether;
        vm.expectEmit(true, false, false, true);
        emit SwapBackToETH(user1, withdrawAmount);

        uint beforeContractBalance = address(weth).balance;
        uint beforeUserETH = user1.balance;

        vm.expectCall(address(weth), 
                    abi.encodeCall(weth.swapBackToETH, (withdrawAmount)));
        weth.swapBackToETH(withdrawAmount);

        // test4
        uint afterContractBalance = address(weth).balance;
        assertEq(beforeContractBalance - afterContractBalance, 
                 withdrawAmount);
        
        // // test5
        uint afterUserETH = user1.balance;
        assertEq(beforeContractBalance - afterContractBalance, 
                 afterUserETH - beforeUserETH);
        vm.stopPrank();
    }
    /**
    測項 7: transfer 應該要將 erc20 token 轉給別人
     */
    function testTransfer() public{
        address user2 = makeAddr("user2");

        vm.startPrank(user1);
        // set user1 1 ether and swap it to weth
        deal(user1, 1 ether);
        weth.swapToWETH{value:1 ether}();
        
        uint beforeTransferUser1 = weth.balanceOf(user1);
        uint beforeTransferUser2 = weth.balanceOf(user2);

        uint transferTokenAmount = 1;
        vm.expectCall(address(weth), abi.encodeCall(weth.transfer, (user2, transferTokenAmount)));
        weth.transfer(user2, transferTokenAmount);

        uint afterTransferUser1 = weth.balanceOf(user1);
        uint afterTransferUser2 = weth.balanceOf(user2);
        assertEq(beforeTransferUser1 - afterTransferUser1, transferTokenAmount);
        assertEq(afterTransferUser2 - beforeTransferUser2, transferTokenAmount);
        vm.stopPrank();
    }

    /**
    測項 8: approve 應該要給他人 allowance
     */
    function testApprove() public{
        address user2 = makeAddr("user2");

        vm.startPrank(user1);
        uint approveAmount = 1 ether;
        assertTrue(weth.approve(user2, approveAmount));
        uint allowanceAmount = weth.allowance(user1, user2);
        assertEq(allowanceAmount, approveAmount);

        vm.stopPrank();
    }
    /**
    測項 9: transferFrom 應該要可以使用他人的 allowance
    測項 10: transferFrom 後應該要減除用完的 allowance
     */
    function testTransferFrom() public{
        address allowanceSpender = makeAddr("allowanceSpender");
        address user2 = makeAddr("user2");

        vm.startPrank(user1);
        // set user1 1 ether and swap it to weth
        deal(user1, 1 ether);
        weth.swapToWETH{value:1 ether}();

        assertTrue(weth.approve(allowanceSpender, 1 ether));
        uint beforeAllowanceAmount = weth.allowance(user1, allowanceSpender);  
        vm.stopPrank();  

        vm.startPrank(allowanceSpender);
        uint transferAmount = 100;
        weth.transferFrom(user1, user2, transferAmount);
        vm.stopPrank();

        vm.prank(user1);
        uint afterAllowanceAmount = weth.allowance(user1, allowanceSpender);  

        assertEq(beforeAllowanceAmount - afterAllowanceAmount, 
                 transferAmount);
        
    }
}