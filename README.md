### check step
---
#### HW7

#### hw7-1 nonft
請實作一個 ERC721 token 和 Receiver Contract
> name(): Don’t send NFT to me。\
> symbol(): “NONFT” \
> metadata image:  “https://imgur.com/IBDi02f” \
> 功能：\
> Receiver 收到一個的其他 ERC721 token (此 Token 隨意設計就行)，若此 Token 非我們上述的 NONFT Token，就將其傳回去給原始 Token owner，同時 mint 一個這個 NONFT token 給 owner。\
> ERC721 請與 Receiver 分成兩個不同的合約。
> 需測試執行完畢原始的 sender 可以收到原本的 token + NONFT token

![Image text](https://github.com/chiaying-lin/school_hw/blob/main/hw7_erc721/metadata/hw7-1_hint.png)

step 1:
```
git clone https://github.com/chiaying-lin/school_hw.git
```
step 2:
```
cd school_hw/hw7_erc721
```
step 3:
```
forge test --mc NONFT
```

#### hw7-2 BlindBox
做一個隨機自由 mint token 的 ERC721

> totalSupply: 500\
> mint(): 基本正常 mint，不要達到上限 500 即可\
> Implement 盲盒機制\
> 請寫測試確認解盲前的 tokenURI 及解盲後的 tokenURI\
> randomMint() 加分項目，隨機 mint tokenId (不重複)\
> 隨機的方式有以下選擇方式
> * 自己製作隨機 random，不限任何方法
> * Chainlink VRF
> * RANDAO
step 1:
```
git clone https://github.com/chiaying-lin/school_hw.git
```
step 2:
```
cd school_hw/hw7_erc721
```
step 3:
```
forge test --mc BlindBoxNFT
```
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
