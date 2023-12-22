pragma solidity ^0.8.13;

import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract AAVEFlashLoan is IFlashLoanSimpleReceiver {
    address constant POOL_ADDRESSES_PROVIDER =
        0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant UNI_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    function execute(bytes calldata data) external {
        (, , , , uint repayAmount) = abi.decode(
            data,
            (address, address, address, address, uint)
        );
        POOL().flashLoanSimple(
            address(this),
            USDC_ADDRESS,
            repayAmount,
            data,
            0
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        (
            CErc20Delegate cUSDC,
            CErc20Delegate cUNI,
            address borrower,
            address liquidator,
            uint repayAmount
        ) = abi.decode(
                params,
                (CErc20Delegate, CErc20Delegate, address, address, uint)
            );
        require(msg.sender == address(POOL()), "AAVEFlashLoan: invalid pool");
        require(asset == USDC_ADDRESS, "AAVEFlashLoan: invalid asset address");
        require(initiator == address(this), "AAVEFlashLoan: invalid initiator");
        require(
            IERC20(asset).balanceOf(address(this)) >= repayAmount,
            "AAVEFlashLoan: not enough balance for repay"
        );

        // liquidate and redeem UNI
        IERC20(USDC_ADDRESS).approve(address(cUSDC), repayAmount);
        uint err = cUSDC.liquidateBorrow(borrower, repayAmount, cUNI);
        require(err == 0, "AAVEFlashLoan: Compound liquidateBorrow failed");
        err = cUNI.redeem(cUNI.balanceOf(address(this)));
        require(err == 0, "AAVEFlashLoan: Compound redeem failed");

        // allow AAVE can take out fee
        uint256 fee = amount + premium;
        IERC20(asset).approve(address(POOL()), fee);
        
        // swap UNI to USDC
        uint amountOut = swapUNItoUSDC();
        console.log("Swap usdc amountOut=", amountOut);
        console.log("AAVE repay and fee=", fee);

        // transfer USDC reward to liquidator
        IERC20(USDC_ADDRESS).transfer(liquidator, amountOut - fee);
        return true;
    }
    
    function swapUNItoUSDC() internal returns (uint256 amountOut)  {
        ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        IERC20(UNI_ADDRESS).approve(address(swapRouter), type(uint256).max);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: UNI_ADDRESS,
                tokenOut: USDC_ADDRESS,
                fee: 3000, // 0.3%
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: IERC20(UNI_ADDRESS).balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(swapParams);
    }

    function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    }

    function POOL() public view returns (IPool) {
        return IPool(ADDRESSES_PROVIDER().getPool());
    }
}
