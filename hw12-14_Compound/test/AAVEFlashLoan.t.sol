// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {EIP20Interface} from "compound-protocol/contracts/EIP20Interface.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {SimplePriceOracle} from "compound-protocol/contracts/SimplePriceOracle.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";
import {AAVEFlashLoan} from "../src/AAVEFlashLoan.sol";

contract LiquidateTest is Test {
    address admin = makeAddr("admin");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2"); // liquidator

    EIP20Interface USDC =
        EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    EIP20Interface UNI =
        EIP20Interface(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    CErc20Delegator cUSDCProxy;
    CErc20Delegator cUNIProxy;
    CErc20Delegate cUSDC;
    CErc20Delegate cUNI;

    CErc20Delegate impl;
    SimplePriceOracle simplePriceOracle;
    WhitePaperInterestRateModel whitePaperModel;
    Comptroller comptroller;
    Unitroller unitroller;
    Comptroller proxyComptroller;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);
        vm.rollFork(17_465_000);

        vm.startPrank(admin);
        impl = new CErc20Delegate();
        simplePriceOracle = new SimplePriceOracle();
        whitePaperModel = new WhitePaperInterestRateModel(0, 0);
        comptroller = new Comptroller();
        unitroller = new Unitroller();

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        proxyComptroller = Comptroller(address(unitroller));

        proxyComptroller._setPriceOracle(simplePriceOracle);

        (cUSDCProxy, cUSDC) = setUpCErc20Delegator(
            address(USDC),
            10 ** USDC.decimals(),
            "Compound USDC Token",
            "cUSDC"
        );

        (cUNIProxy, cUNI) = setUpCErc20Delegator(
            address(UNI),
            10 ** UNI.decimals(),
            "Compound UNI Token",
            "cUNI"
        );

        simplePriceOracle.setDirectPrice(
            address(USDC),
            1 * 10 ** (36 - USDC.decimals())
        );
        simplePriceOracle.setDirectPrice(
            address(UNI),
            5 * 10 ** (36 - UNI.decimals())
        );

        proxyComptroller._setCloseFactor(5 * 1e17);
        proxyComptroller._setCollateralFactor(cUNI, 5e17);
        proxyComptroller._setLiquidationIncentive(1.08 * 1e18);

        // provide some USDC to compound pool
        uint256 initBalanceOfUSDC = 10000 * 10 ** USDC.decimals();
        deal(address(USDC), admin, initBalanceOfUSDC);
        USDC.approve(address(cUSDC), initBalanceOfUSDC);
        cUSDC.mint(initBalanceOfUSDC);

        vm.stopPrank();
    }

    // user1 use uni to borrow usdc
    // user2(liqudator) use AAVE flash loan to do liquidate
    function test_AAVE_Flash_Loan_Liquidate() public {
        user1_use_uni_to_borrow_usdc();
        decrease_uni_price();

        // user2 use AAVE flash loan to do liquidate
        vm.startPrank(user2);
        // calucate repay amount
        uint closeFactorMantissa = proxyComptroller.closeFactorMantissa();
        uint borrowBalance = cUSDC.borrowBalanceCurrent(user1);
        uint repayAmount = (borrowBalance * closeFactorMantissa) / 1e18;

        // user2 use AAVE flash loan to do liquidate
        bytes memory data = abi.encode(cUSDC, cUNI, user1, user2, repayAmount);
        AAVEFlashLoan flashLoan = new AAVEFlashLoan();
        flashLoan.execute(data);

        // check liquidate result
        console2.log(
            "USDC Balance=",
            USDC.balanceOf(user2) / 10 ** USDC.decimals()
        );
        assertEq(63, USDC.balanceOf(user2) / 10 ** USDC.decimals());

        vm.stopPrank();
    }

    function setUpCErc20Delegator(
        address underlyingToken,
        uint initialExchangeRateMantissa,
        string memory name,
        string memory symbol
    ) private returns (CErc20Delegator delegator, CErc20Delegate cToken) {
        delegator = new CErc20Delegator(
            underlyingToken,
            proxyComptroller,
            whitePaperModel,
            initialExchangeRateMantissa,
            name,
            symbol,
            18,
            payable(admin),
            address(impl),
            new bytes(0)
        );
        cToken = CErc20Delegate(address(delegator));
        proxyComptroller._supportMarket(cToken);
    }

    function user1_use_uni_to_borrow_usdc() internal {
        uint256 initBalanceOfUNI = 1000 * 10 ** UNI.decimals();
        deal(address(UNI), user1, initBalanceOfUNI);

        vm.startPrank(user1);
        // supply UNI and get cUNI
        UNI.approve(address(cUNI), initBalanceOfUNI);
        uint mintStatus = cUNI.mint(initBalanceOfUNI);
        assertEq(mintStatus, 0);

        // let cUNI to be collateral
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cUNI);
        proxyComptroller.enterMarkets(cTokens);

        // borrow USDC
        uint256 borrowAmount = 2500 * 10 ** USDC.decimals();
        uint errCode = cUSDC.borrow(borrowAmount);
        require(errCode == 0, "borrow failed");
        assertEq(USDC.balanceOf(user1), borrowAmount);

        vm.stopPrank();
    }

    function decrease_uni_price() internal {
        vm.prank(admin);
        simplePriceOracle.setDirectPrice(
            address(UNI),
            4 * 10 ** (36 - UNI.decimals())
        );

        (uint err, ,uint shortfall) = proxyComptroller.getAccountLiquidity(
            user1
        );
        assertEq(err, 0);
        require(shortfall > 0, "user1 should be undercollateralized");
    }
}
