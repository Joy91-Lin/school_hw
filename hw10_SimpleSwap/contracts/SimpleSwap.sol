// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";


contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    address public token0;
    address public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    constructor(address _token0, address _token1) 
        ERC20("SimpleSwap Liquidity Provider Token", "LP") {
        require(_isContract(_token0), 'SimpleSwap: TOKENA_IS_NOT_CONTRACT');
        require(_isContract(_token1), 'SimpleSwap: TOKENB_IS_NOT_CONTRACT');
        require(_token0 != _token1, 'SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS');
        if(uint256(uint160(_token0)) < uint256(uint160(_token1))){
            token0 = _token0;   
            token1 = _token1;
        } else {
            token0 = _token1;
            token1 = _token0;
        }
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut){
        require(tokenIn == token0 || tokenIn == token1, 'SimpleSwap: INVALID_TOKEN_IN');
        require(tokenOut == token0 || tokenOut == token1, 'SimpleSwap: INVALID_TOKEN_OUT');
        require(tokenIn != tokenOut, 'SimpleSwap: IDENTICAL_ADDRESS');
        require(amountIn > 0, 'SimpleSwap: INSUFFICIENT_INPUT_AMOUNT');
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint256 reserveIn = tokenIn == token0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenOut == token0 ? reserve0 : reserve1;
        
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);

        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        require(balance0 * balance1 >= reserve0 * reserve1, 'SimpleSwap: K');

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        _update(balance0, balance1);
    }

    function _addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) internal view returns (uint256 amountA, uint256 amountB){
        if(totalSupply() == 0){
            (amountA, amountB) = (amountAIn, amountBIn);
        } else {
            uint256 amountBOptimal = _quote(amountAIn, reserve0, reserve1);
            if(amountBOptimal <= amountBIn){
                (amountA, amountB) = (amountAIn, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(amountBIn, reserve1, reserve0);
                (amountA, amountB) = (amountAOptimal, amountBIn);
            }
        }
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        require(amountAIn > 0 && amountBIn > 0, 'SimpleSwap: INSUFFICIENT_INPUT_AMOUNT');
        (amountA, amountB) = _addLiquidity(amountAIn, amountBIn);
        ERC20(token0).transferFrom(msg.sender, address(this), amountA);
        ERC20(token1).transferFrom(msg.sender, address(this), amountB);
        liquidity = mint(msg.sender);
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(
        uint256 liquidity)
    external returns (uint256 amountA, uint256 amountB){
        _transfer(msg.sender, address(this), liquidity);
        (amountA, amountB) = burn(msg.sender);
    }

    function getReserves() external view returns (uint256 reserveA, uint256 reserveB){
        reserveA = reserve0;
        reserveB = reserve1;
    }

    function getTokenA() external view returns (address tokenA){
        tokenA = token0;
    }

    function getTokenB() external view returns (address tokenB){
        tokenB = token1;
    }

    function mint(address to) internal returns (uint liquidity) {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        uint _totalSupply = totalSupply(); 
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1);
        } else {
            liquidity = Math.min(amount0 * _totalSupply / reserve0, amount1 * _totalSupply / reserve1);
        }
        require(liquidity > 0, 'SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
    }
    
    function burn(
        address to)
    internal returns (uint256 amountA, uint256 amountB){
        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        uint256 _totalSupply = totalSupply();
        amountA = liquidity * balance0 / _totalSupply;
        amountB = liquidity * balance1 / _totalSupply;

        require(amountA > 0 && amountB > 0, 'SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        ERC20(token0).transfer(to, amountA);
        ERC20(token1).transfer(to, amountB);

        _update(balance0, balance1);
    }

    function _update(uint256 balance0, uint256 balance1) internal {
        reserve0 = balance0;
        reserve1 = balance1;
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function _quote(uint256 _amount0, uint256 _reserve0, uint256 _reserve1) internal pure returns (uint256 _amount1) {
        require(_amount0 > 0, 'SimpleSwap: INSUFFICIENT_AMOUNT');
        require(_reserve0 > 0 && _reserve1 > 0, 'SimpleSwap: INSUFFICIENT_LIQUIDITY');
        _amount1 = (_amount0 * _reserve1) / _reserve0;
    }

    // 利用 extcodesize 检查是否为合约
    function _isContract(address account) internal view returns (bool) {
        // extcodesize > 0 的地址一定是合约地址
        // 但是合约在构造函数时候 extcodesize 为0
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
