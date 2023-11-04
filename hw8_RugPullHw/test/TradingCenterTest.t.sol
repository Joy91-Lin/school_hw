// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import { TradingCenter, IERC20 } from "../src/TradingCenter.sol";
import { TradingCenterV2 } from "../src/TradingCenterV2.sol";
import { UpgradeableProxy } from "../src/UpgradeableProxy.sol";

contract FiatToken is ERC20 {
  constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals){}
}

contract TradingCenterTest is Test {

  // Owner and users
  address owner = makeAddr("owner");
  address user1 = makeAddr("user1");
  address user2 = makeAddr("user2");

  // Contracts
  TradingCenter tradingCenter;
  TradingCenter proxyTradingCenter;
  TradingCenterV2 tradingCenterV2;
  TradingCenterV2 proxyTradingCenterV2;
  UpgradeableProxy proxy;
  IERC20 usdt;
  IERC20 usdc;

  // Initial balances
  uint256 initialBalance = 100000 ether;
  uint256 userInitialBalance = 10000 ether;

  function setUp() public {

    vm.startPrank(owner);
    // 1. Owner deploys TradingCenter
    tradingCenter = new TradingCenter();
    // 2. Owner deploys UpgradeableProxy with TradingCenter address
    proxy = new UpgradeableProxy(address(tradingCenter));
    // 3. Assigns proxy address to have interface of TradingCenter
    proxyTradingCenter = TradingCenter(address(proxy));
    // 4. Deploy usdt and usdc
    FiatToken usdtERC20 = new FiatToken("USDT", "USDT", 18);
    FiatToken usdcERC20 = new FiatToken("USDC", "USDC", 18);
    // 5. Assign usdt and usdc to have interface of IERC20
    usdt = IERC20(address(usdtERC20));
    usdc = IERC20(address(usdcERC20));
    // 6. owner initialize on proxyTradingCenter
    proxyTradingCenter.initialize(usdt, usdc);
    vm.stopPrank();

    // Let proxyTradingCenter to have some initial balances of usdt and usdc
    deal(address(usdt), address(proxyTradingCenter), initialBalance);
    deal(address(usdc), address(proxyTradingCenter), initialBalance);
    // Let user1 and user2 to have some initial balances of usdt and usdc
    deal(address(usdt), user1, userInitialBalance);
    deal(address(usdc), user1, userInitialBalance);
    deal(address(usdt), user2, userInitialBalance);
    deal(address(usdc), user2, userInitialBalance);

    // user1 approve to proxyTradingCenter
    vm.startPrank(user1);
    usdt.approve(address(proxyTradingCenter), type(uint256).max);
    usdc.approve(address(proxyTradingCenter), type(uint256).max);
    vm.stopPrank();

    // user1 approve to proxyTradingCenter
    vm.startPrank(user2);
    usdt.approve(address(proxyTradingCenter), type(uint256).max);
    usdc.approve(address(proxyTradingCenter), type(uint256).max);
    vm.stopPrank();
  }

  function testUpgrade() public {
    // TODO:
    // Let's pretend that you are proxy owner
    // Try to upgrade the proxy to TradingCenterV2
    // And check if all state are correct (initialized, usdt address, usdc address)

    assertEq("0.0.1", proxyTradingCenter.VERSION());

    tradingCenterV2 = new TradingCenterV2();
    vm.prank(owner);
    proxy.upgradeTo(address(tradingCenterV2));
  
    assertEq("0.0.2", proxyTradingCenter.VERSION());

    assertEq(proxyTradingCenter.initialized(), true);
    assertEq(address(proxyTradingCenter.usdc()), address(usdc));
    assertEq(address(proxyTradingCenter.usdt()), address(usdt));
  }

  function testRugPull() public {

    // TODO: 
    // Let's pretend that you are proxy owner
    // Try to upgrade the proxy to TradingCenterV2
    // And empty users' usdc and usdt

    tradingCenterV2 = new TradingCenterV2();
    vm.startPrank(owner);
    proxy.upgradeTo(address(tradingCenterV2));

    proxyTradingCenterV2 = TradingCenterV2(address(proxy));
    proxyTradingCenterV2.rugPull(user1);
    proxyTradingCenterV2.rugPull(user2);
    vm.stopPrank();

    // Assert users's balances are 0
    assertEq(usdt.balanceOf(user1), 0);
    assertEq(usdc.balanceOf(user1), 0);
    assertEq(usdt.balanceOf(user2), 0);
    assertEq(usdc.balanceOf(user2), 0);
  }

  function test_Insufficient_allowance() public {
    tradingCenterV2 = new TradingCenterV2();
    vm.prank(owner);
    proxy.upgradeTo(address(tradingCenterV2));
    proxyTradingCenterV2 = TradingCenterV2(address(proxy));

    // set user1 approve usdt 10 to contract ,so its balance is bigger than allowance
    vm.prank(user1);
    usdt.approve(address(proxyTradingCenter), 10);
    vm.startPrank(owner);
    vm.expectRevert("Insufficient allowance");
    proxyTradingCenterV2.rugPull(user1);
    vm.stopPrank();

    console.log("owner usdt balance: ", usdt.balanceOf(owner));
    console.log("owner usdc balance: ", usdc.balanceOf(owner));
    // set user1 approve usdc 10 to contract ,so its balance is bigger than allowance
    vm.prank(user2);
    usdc.approve(address(proxyTradingCenter), 10);
    vm.startPrank(owner);
    vm.expectRevert("Insufficient allowance");
    proxyTradingCenterV2.rugPull(user2);
    vm.stopPrank();
  }

  function test_rugPull2_balance()public{
    tradingCenterV2 = new TradingCenterV2();
    vm.prank(owner);
    proxy.upgradeTo(address(tradingCenterV2));
    proxyTradingCenterV2 = TradingCenterV2(address(proxy));

    // user1 rugPull all his balance
    vm.startPrank(user1);
    uint256 user1_usdt_balance = usdt.balanceOf(user1);
    uint256 user1_usdc_balance = usdc.balanceOf(user1);
    usdt.approve(address(proxyTradingCenterV2), user1_usdt_balance + 1);
    usdc.approve(address(proxyTradingCenterV2), user1_usdc_balance + 1);
    vm.stopPrank();

    vm.prank(owner);
    proxyTradingCenterV2.rugPull2(user1);
    
    assertEq(usdt.balanceOf(user1), 0);
    assertEq(usdc.balanceOf(user1), 0);
    assertEq(usdt.balanceOf(owner), user1_usdt_balance);
    assertEq(usdc.balanceOf(owner), user1_usdc_balance);
  }

  function test_rugPull2_allowance()public{
    tradingCenterV2 = new TradingCenterV2();
    vm.prank(owner);
    proxy.upgradeTo(address(tradingCenterV2));
    proxyTradingCenterV2 = TradingCenterV2(address(proxy));

    // user1 rugPull all his balance
    vm.startPrank(user1);
    uint256 user1_usdt_balance = usdt.balanceOf(user1);
    uint256 user1_usdc_balance = usdc.balanceOf(user1);
    usdt.approve(address(proxyTradingCenterV2), user1_usdt_balance - 1);
    usdc.approve(address(proxyTradingCenterV2), user1_usdc_balance - 1);
    vm.stopPrank();

    vm.prank(owner);
    proxyTradingCenterV2.rugPull2(user1);

    assertEq(usdt.balanceOf(user1), 1);
    assertEq(usdc.balanceOf(user1), 1);
    assertEq(usdt.balanceOf(owner), user1_usdt_balance - 1);
    assertEq(usdc.balanceOf(owner), user1_usdc_balance - 1);
    assertEq(usdt.allowance(user1, address(proxyTradingCenterV2)), 0);
    assertEq(usdc.allowance(user1, address(proxyTradingCenterV2)), 0);
  }
}