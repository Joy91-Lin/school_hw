// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";

// This is a practice contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {
    struct ArbitrageInfo {
        address priceLowerPool;
        address priceHigherPool;
        uint256 method;
    }

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        // TODO
        require(sender == address(this), "Sender must be this contract");
        require(amount0 == 0 || amount1 == 0, "One of the amount must be 0");

        ArbitrageInfo memory arbitrageInfo = abi.decode(data, (ArbitrageInfo));

        address weth = IUniswapV2Pair(arbitrageInfo.priceLowerPool).token0();
        address usdc = IUniswapV2Pair(arbitrageInfo.priceLowerPool).token1();

        if (arbitrageInfo.method == 1) {
            require(msg.sender == arbitrageInfo.priceLowerPool, "Sender must be uniswap pair");
            // 1. 將 amount0 的 WETH 傳給 higher price pool
            IERC20(weth).transfer(address(arbitrageInfo.priceHigherPool), amount0);

            // 2. 從 higher price pool 交換出 USDC
            (uint112 reserveWETHHigherPool, uint112 reserveUSDCHigherPool, ) = IUniswapV2Pair(arbitrageInfo.priceHigherPool).getReserves();
            uint256 usdc_amountOut = _getAmountOut(amount0, reserveWETHHigherPool, reserveUSDCHigherPool);
            IUniswapV2Pair(arbitrageInfo.priceHigherPool).swap(0, usdc_amountOut, address(this), "");

            // 3. 將 USDC 傳回 lower price pool
            (uint112 reserveWETHLowerPool, uint112 reserveUSDCLowerPool, ) = IUniswapV2Pair(arbitrageInfo.priceLowerPool).getReserves();
            uint256 usdc_amountIn = _getAmountIn(amount0, reserveUSDCLowerPool, reserveWETHLowerPool);
            IERC20(usdc).transfer(address(arbitrageInfo.priceLowerPool), usdc_amountIn);
        } else if(arbitrageInfo.method == 2) {
            require(msg.sender == arbitrageInfo.priceHigherPool, "Sender must be uniswap pair");
            // 1. 將 amount1 的 USDC 傳給 lower price pool
            IERC20(usdc).transfer(address(arbitrageInfo.priceLowerPool), amount1);

            // 2. 從 lower price pool 交換出 WETH
            (uint112 reserveWETHLowerPool, uint112 reserveUSDCLowerPool, ) = IUniswapV2Pair(arbitrageInfo.priceLowerPool).getReserves();
            uint256 weth_amountOut = _getAmountOut(amount1, reserveUSDCLowerPool, reserveWETHLowerPool);
            IUniswapV2Pair(arbitrageInfo.priceLowerPool).swap(weth_amountOut, 0, address(this), "");

            // 3. 將 WETH 傳回 higher price pool
            (uint112 reserveWETHHigherPool, uint112 reserveUSDCHigherPool, ) = IUniswapV2Pair(arbitrageInfo.priceHigherPool).getReserves();
            uint256 weth_amountIn = _getAmountIn(amount1, reserveWETHHigherPool, reserveUSDCHigherPool);
            IERC20(weth).transfer(address(arbitrageInfo.priceHigherPool), weth_amountIn);
        } else {
            revert("Invalid method");
        }
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool
    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowETH) external {
        // TODO
        ArbitrageInfo memory data = ArbitrageInfo(priceLowerPool, priceHigherPool, 1);
        IUniswapV2Pair(priceLowerPool).swap(borrowETH, 0, address(this), abi.encode(data));
    }

    // Method 2
    function arbitrage_method2(address priceLowerPool, address priceHigherPool, uint256 borrowUSDC) external {
        // TODO
        ArbitrageInfo memory data = ArbitrageInfo(priceLowerPool, priceHigherPool, 2);
        IUniswapV2Pair(priceHigherPool).swap(0, borrowUSDC, address(this), abi.encode(data));
    }

    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
