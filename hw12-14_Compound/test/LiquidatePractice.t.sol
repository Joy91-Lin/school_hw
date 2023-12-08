// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {PriceOracle} from "compound-protocol/contracts/PriceOracle.sol";
import {SimplePriceOracle} from "compound-protocol/contracts/SimplePriceOracle.sol";


contract LiquidateTest is Test {
    address payable user1 = payable(0x4ff1B1f7b28345eFC5e8f628A19e96c34696dbF0);
    address payable user2 = payable(0x2bb5DCDadDF4d8f3aCC8de72B93F28137b404737); // liquidator
    
    EIP20Interface public USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    EIP20Interface DAI = EIP20Interface(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 cDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    PriceOracle oracle = PriceOracle(0xDDc46a3B076aec7ab3Fc37420A8eDd2959764Ec4);

    Comptroller comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);

        uint256 initBalanceOfUSDC = 10000 * 10 ** USDC.decimals();
        deal(address(USDC), user1, initBalanceOfUSDC);
        // deal(address(USDC), user2, initBalanceOfUSDC);
        uint256 initBalanceOfDAI = 10000 * 10 ** DAI.decimals();
        // deal(address(DAI), user1, initBalanceOfDAI);
        deal(address(DAI), user2, initBalanceOfDAI);
    }
    // user1 use usdc to borrow dai
    // user2(liqudator) repay dai and seize usdc
    function test_liquidate()public{
        user1_use_usdc_to_borrow_dai();
        change_collateral_factor();
        console2.log("----------------------");

        // liquidate
        vm.startPrank(user2);
        uint closeFactorMantissa = comptroller.closeFactorMantissa();
        uint borrowBalance = cDAI.borrowBalanceCurrent(user1);
        uint repayAmount = borrowBalance * closeFactorMantissa / 1e18;
        console2.log("close Factor: ", closeFactorMantissa / 1e16, " %");
        console2.log("repayAmount : ", repayAmount / 10 ** DAI.decimals());

        DAI.approve(address(cDAI),  repayAmount);
        (uint err) =  cDAI.liquidateBorrow(user1, repayAmount, cUSDC);
        require(err == 0, "liquidate failed");

        console2.log("Liquidation Incentive cUSDC amount: ", cUSDC.balanceOf(user2));
        
        vm.stopPrank();
    }

    function user1_use_usdc_to_borrow_dai() internal {
         vm.startPrank(user1);
        // supply USDC and get cUSDC
        uint256 collateralAmount = 100 * 10 ** USDC.decimals();
        USDC.approve(address(cUSDC), collateralAmount);
        (uint mintStatus) = cUSDC.mint(collateralAmount);
        assertEq(mintStatus, 0);

        // let cUSDC to be collateral
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cUSDC);
        comptroller.enterMarkets(cTokens);
        
        // borrow DAI
        uint256 borrowAmount = 70 * 10 ** DAI.decimals();
        (uint errCode) = cDAI.borrow(borrowAmount);
        require(errCode == 0, "borrow failed");
        assertEq(DAI.balanceOf(user1), borrowAmount);

        vm.stopPrank();
    }
    
    // let user1 be liquidated
    function change_collateral_factor() internal {
        // get AccountLiquidity of user1
        console2.log("<< user1 Account Liquidity Before Change Collateral Factor>>");
        (uint err, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(user1);
        require(err == 0, "getAccountLiquidity failed");
        console2.log("user1 liquidity: ", liquidity);
        console2.log("user1 shortfall: ", shortfall);

        // get collateral factor of USDC
        (, uint collateralFactorMantissa, ) = comptroller.markets(address(cUSDC));
        console2.log("collateral factor: ", collateralFactorMantissa / 1e16, " %");

        vm.prank(0x6d903f6003cca6255D85CcA4D3B5E5146dC33925);
        comptroller._setCollateralFactor(cUSDC, 10 * 10 ** 16);

        console2.log("<< user1 Account Liquidity After Change Collateral Factor>>");
        (err,liquidity, shortfall) = comptroller.getAccountLiquidity(user1);
        assertEq(err, 0);
        console2.log("user1 liquidity: ", liquidity);
        console2.log("user1 shortfall: ", shortfall);
        require(shortfall > 0, "user1 should be undercollateralized");
        (, collateralFactorMantissa, ) = comptroller.markets(address(cUSDC));
        console2.log("collateral factor: ", collateralFactorMantissa / 1e16, " %");
    }

}