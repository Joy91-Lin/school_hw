# school_hw

### check step
---
#### HW6
> 實作Wrapped ETH token的測試程式\
> 測試項目：\
> 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user\
> 測項 2: deposit 應該將 msg.value 的 ether 轉入合約\
> 測項 3: deposit 應該要 emit Deposit event\
> 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token\
> 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user\
> 測項 6: withdraw 應該要 emit Withdraw event\
> 測項 7: transfer 應該要將 erc20 token 轉給別人\
> 測項 8: approve 應該要給他人 allowance\
> 測項 9: transferFrom 應該要可以使用他人的 allowance\
> 測項 10: transferFrom 後應該要減除用完的 allowance\


step 1:
```
git clone https://github.com/chiaying-lin/school_hw.git
```
step 2:
```
cd school_hw/hw6_WETH
```
step 3:
```
forge test --mc WETHTest
```
