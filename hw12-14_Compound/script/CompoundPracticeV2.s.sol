// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {SimplePriceOracle} from "compound-protocol/contracts/SimplePriceOracle.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";

contract UnderlyingTokenA is ERC20 {
    constructor() ERC20("token A", "AA") {}
}

contract UnderlyingTokenB is ERC20 {
    constructor() ERC20("token B", "BB") {}
}

contract CompoundPracticeV2Script is Script {
    CErc20Delegator cTokenAProxy;
    CErc20Delegator cTokenBProxy;
    CErc20Delegate cTokenA;
    CErc20Delegate cTokenB;
    ERC20 tokenA;
    ERC20 tokenB;
    Unitroller unitroller;
    Comptroller comptroller;
    Comptroller proxyComptroller;
    SimplePriceOracle oracle;
    WhitePaperInterestRateModel whitePaperModel;
    CErc20Delegate cERC20_impl;

    address admin;

    function run() public {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);
        
        admin = vm.envAddress("ADMIN");
        tokenA = new UnderlyingTokenA();
        tokenB = new UnderlyingTokenB();
        comptroller = new Comptroller();
        whitePaperModel = new WhitePaperInterestRateModel(0, 0);
        cERC20_impl = new CErc20Delegate();
        oracle = new SimplePriceOracle();

        unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        proxyComptroller = Comptroller(address(unitroller));
        proxyComptroller._setPriceOracle(oracle);
        // set tokenA price 1 usd and collateral factor 50%
        (cTokenAProxy, cTokenA) = setUpCErc20Delegator(address(tokenA), "Compound A Token", "cAA", 1e18, 5e17);
        // set tokenB price 100 usd and collateral factor 50%
        (cTokenBProxy, cTokenB) = setUpCErc20Delegator(address(tokenB), "Compound B Token", "cBB", 1e20, 5e17);

        proxyComptroller._setCloseFactor(5e17);
        proxyComptroller._setLiquidationIncentive(108 * 1e16);
        // proxyComptroller._setLiquidationIncentive(1 * 1e18);
        vm.stopBroadcast();
    }

    function setUpCErc20Delegator (
        address underlyingToken,
        string memory name,
        string memory symbol,
        uint underlyingPriceMantissa,
        uint collateralFactorMantissa
    ) private returns (CErc20Delegator delegator, CErc20Delegate cToken){
        delegator = new CErc20Delegator(
                underlyingToken,
                proxyComptroller,
                whitePaperModel,
                1e18,
                name,
                symbol,
                18,
                payable(admin),
                address(cERC20_impl),
                new bytes(0)
         );
        cToken = CErc20Delegate(address(delegator));
        proxyComptroller._supportMarket(cToken);
        oracle.setUnderlyingPrice(cToken, underlyingPriceMantissa);
        proxyComptroller._setCollateralFactor(CErc20Delegate(address(delegator)), collateralFactorMantissa);
    }
}