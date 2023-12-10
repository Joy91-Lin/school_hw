// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../script/CompoundPracticeV2.s.sol";

contract CompoundPracticeV2Test is Test, CompoundPracticeV2Script {
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address provider = makeAddr("provider");
    
    function setUp() public {
        run();

        // assertEq(oracle.getUnderlyingPrice(cTokenA)/1e18, 1);
        // assertEq(oracle.getUnderlyingPrice(cTokenB)/1e18, 100);

        // provide tokenA into Compound
        deal(address(tokenA), provider, 100 * 10 ** tokenA.decimals());
        vm.startPrank(provider);
        tokenA.approve(address(cTokenA), type(uint256).max);
        uint errorCode = cTokenA.mint(100 * 10 ** tokenA.decimals());
        assertEq(errorCode, 0);
        vm.stopPrank();
        
        uint tokenBAmount = 1 * 10 ** tokenB.decimals();
        deal(address(tokenB), user1, tokenBAmount);

        uint tokenAAmount = 100 * 10 ** tokenA.decimals();
        deal(address(tokenA), user2, tokenAAmount);


        // mint tokenB
        vm.startPrank(user1);
        tokenB.approve(address(cTokenB), tokenBAmount);
        errorCode = cTokenB.mint(tokenBAmount);
        assertEq(errorCode, 0);
        assertEq(cTokenB.balanceOf(user1), tokenBAmount);

        // use cTokenB as collateral
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenB);
        proxyComptroller.enterMarkets(cTokens);

        // borrow  50 tokenA
        uint borrowAmount = 50 * 10 ** tokenA.decimals();
        errorCode = cTokenA.borrow(borrowAmount);
        assertEq(errorCode, 0);
        assertEq(cTokenA.borrowBalanceCurrent(user1), borrowAmount);
        assertEq(tokenA.balanceOf(user1), borrowAmount);
        vm.stopPrank();
    }
    function test_decrease_collateral_factor()public{
        // decrease collateral factor 50% -> 10%
        vm.prank(admin);
        uint errorCode = proxyComptroller._setCollateralFactor(cTokenB, 1e17);

        (uint err, uint liquidity, uint shortfall) = proxyComptroller.getAccountLiquidity(user1);
        assertEq(err, 0);
        assertEq(liquidity, 0);
        assertGt(shortfall, 0);
        
        // calucate repay amount
        uint closeFactorMantissa = proxyComptroller.closeFactorMantissa();
        uint borrowBalance = cTokenA.borrowBalanceCurrent(user1);
        uint repayAmount = borrowBalance * closeFactorMantissa / 1e18;
        
        // liquidate
        vm.startPrank(user2);
        tokenA.approve(address(cTokenA), repayAmount);
        errorCode = cTokenA.liquidateBorrow(user1, repayAmount, cTokenB);
        assertEq(errorCode, 0);

        // check liquidation incentive
        uint liquidationIncentive = proxyComptroller.liquidationIncentiveMantissa();
        uint tokenSpread = repayAmount * oracle.getUnderlyingPrice(cTokenA) / oracle.getUnderlyingPrice(cTokenB);
        uint seizeAmount = tokenSpread * liquidationIncentive / 1e18;
        seizeAmount = seizeAmount * (1e18 - cTokenB.protocolSeizeShareMantissa()) / 1e18;
        assertEq(cTokenB.balanceOf(user2), seizeAmount);
        vm.stopPrank();
    }

    function test_decrease_collateral_price()public{
        // decrease collateral price 100 -> 50
        vm.prank(admin);
        oracle.setUnderlyingPrice(cTokenB, 50 * 1e18);

        (uint errorCode, uint liquidity, uint shortfall) = proxyComptroller.getAccountLiquidity(user1);
        assertEq(errorCode, 0);
        assertEq(liquidity, 0);
        assertGt(shortfall, 0);

        // calucate repay amount
        uint closeFactorMantissa = proxyComptroller.closeFactorMantissa();
        uint borrowBalance = cTokenA.borrowBalanceCurrent(user1);
        uint repayAmount = borrowBalance * closeFactorMantissa / 1e18;
        
        // liquidate
        vm.startPrank(user2);
        tokenA.approve(address(cTokenA), repayAmount);
        errorCode = cTokenA.liquidateBorrow(user1, repayAmount, cTokenB);
        assertEq(errorCode, 0);

        // check liquidation incentive
        uint liquidationIncentive = proxyComptroller.liquidationIncentiveMantissa();
        uint tokenSpread = repayAmount * oracle.getUnderlyingPrice(cTokenA) / oracle.getUnderlyingPrice(cTokenB);
        uint seizeAmount = tokenSpread * liquidationIncentive / 1e18;
        seizeAmount = seizeAmount * (1e18 - cTokenB.protocolSeizeShareMantissa()) / 1e18;
        assertEq(cTokenB.balanceOf(user2), seizeAmount);
    }
}
