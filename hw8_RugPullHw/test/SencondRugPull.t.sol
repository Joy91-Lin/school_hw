pragma solidity 0.8.20;

import "forge-std/Test.sol";
import { FiatTokenV3 } from "../src/SecondRugPull.sol";

interface IAdminUpgradeabilityProxy{
    function admin() external view returns (address);
    function implementation() external view returns (address);
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external; 
    function upgradeToAndCall(address newImplementation, bytes memory data) payable external;
}

contract FiatTokenV3Test is Test{
    address constant admin = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    address whiteListAdmin = makeAddr("whiteListAdmin");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    IAdminUpgradeabilityProxy proxyContract;
    FiatTokenV3 fiatTokenV3;
    FiatTokenV3 proxyfiatTokenV3;

    
    function setUp() public{
        proxyContract = IAdminUpgradeabilityProxy(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);

    }

    function test_white_list_upgradeContract_without_data_()public{
        // upgrade to V3
        vm.startPrank(admin);
        fiatTokenV3 = new FiatTokenV3();
        proxyContract.upgradeTo(address(fiatTokenV3));
        proxyfiatTokenV3 = FiatTokenV3(address(proxyContract));
        vm.stopPrank();

        // check upgrade successfullly
        assertEq(proxyfiatTokenV3.version(), "3");

        // can not set white list until initialize
        vm.expectRevert("Please initialize the contract first.");
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.setWhiteList(user1);

        // can not use changeAdmin function to set whiteListAdmin for first time
        vm.expectRevert("Please initialize the contract first.");
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.changeAdmin(whiteListAdmin);

        // initialize
        proxyfiatTokenV3.initializerV3(whiteListAdmin);

        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.setWhiteList(user1);
    }

    function test_white_list_upgrade_with_initialize() public {
        // upgrade to V3
        vm.startPrank(admin);
        fiatTokenV3 = new FiatTokenV3();
        proxyContract.upgradeToAndCall(address(fiatTokenV3),
            abi.encodeWithSelector(fiatTokenV3.initializerV3.selector, whiteListAdmin));
        proxyfiatTokenV3 = FiatTokenV3(address(proxyContract));
        vm.stopPrank();

        // admin can only call functions which are in proxy contract
        vm.expectRevert("Cannot call fallback function from the proxy admin");
        vm.prank(admin);
        proxyfiatTokenV3.setWhiteList(user1);

        // set user1 in white list ->failed because user1 is not in white list admin
        vm.expectRevert("only white list admin can call this function.");
        vm.prank(user1);
        proxyfiatTokenV3.setWhiteList(user1);

        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.setWhiteList(user1);

        // change white list admin
        address whiteListAdmin2 = makeAddr("whiteListAdmin2");
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.changeAdmin(whiteListAdmin2);

        vm.expectRevert("only white list admin can call this function.");
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.setWhiteList(user2);

        vm.prank(whiteListAdmin2);
        proxyfiatTokenV3.setWhiteList(user2);
    }

    function test_white_list_admin()public{
        // upgrade to V3
        vm.startPrank(admin);
        fiatTokenV3 = new FiatTokenV3();
        proxyContract.upgradeToAndCall(address(fiatTokenV3),
            abi.encodeWithSelector(fiatTokenV3.initializerV3.selector, whiteListAdmin));
        proxyfiatTokenV3 = FiatTokenV3(address(proxyContract));
        vm.stopPrank();

        // white list admin can not be address(0)
        vm.expectRevert("Invalid address");
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.changeAdmin(address(0));

        // white list admin can not be admin
        vm.expectRevert("Invalid address");
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.changeAdmin(admin);
    }

    function test_mint()public{
        // upgrade to V3
        vm.startPrank(admin);
        fiatTokenV3 = new FiatTokenV3();
        proxyContract.upgradeToAndCall(address(fiatTokenV3),
            abi.encodeWithSelector(fiatTokenV3.initializerV3.selector, whiteListAdmin));
        proxyfiatTokenV3 = FiatTokenV3(address(proxyContract));
        vm.stopPrank();

        // set user1 in white list
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.setWhiteList(user1);
        
        // test user1 mint token to user2 
        uint mintAmount = 100;
        uint totalSupplyBeforeMint = proxyfiatTokenV3.totalSupply();
        vm.prank(user1);
        proxyfiatTokenV3.mint(user2, mintAmount);
        uint totalSupplyAfterMint = proxyfiatTokenV3.totalSupply();
        assertEq(mintAmount, totalSupplyAfterMint - totalSupplyBeforeMint);
        assertEq(mintAmount, proxyfiatTokenV3.balanceOf(user2));

        // test user1 mint token to itself
        vm.prank(user1);
        proxyfiatTokenV3.mint(user1, mintAmount);
        assertEq(mintAmount, proxyfiatTokenV3.balanceOf(user1));

        // test user2 mint token to iself -> fail because user2 is not in white list
        vm.expectRevert("only white list members can call this function.");
        vm.prank(user2);
        proxyfiatTokenV3.mint(user2, mintAmount);
    }

    function test_transfer()public{
        // upgrade to V3
        vm.startPrank(admin);
        fiatTokenV3 = new FiatTokenV3();
        proxyContract.upgradeToAndCall(address(fiatTokenV3),
            abi.encodeWithSelector(fiatTokenV3.initializerV3.selector, whiteListAdmin));
        proxyfiatTokenV3 = FiatTokenV3(address(proxyContract));
        vm.stopPrank();

        // set user1 in white list
        vm.prank(whiteListAdmin);
        proxyfiatTokenV3.setWhiteList(user1);
        vm.prank(user1);
        proxyfiatTokenV3.mint(user1, 100);

        // test user1 transfer token to user2
        uint transferAmount = proxyfiatTokenV3.balanceOf(user1);
        vm.prank(user1);
        proxyfiatTokenV3.transfer(user2, transferAmount);
        assertEq(0, proxyfiatTokenV3.balanceOf(user1));
        assertEq(transferAmount, proxyfiatTokenV3.balanceOf(user2));

        // test insufficient balance
        vm.expectRevert("ERC20: insufficient balance");
        vm.prank(user1);
        proxyfiatTokenV3.transfer(user2, 10);

        // test user2 transfer token to itself -> fail because user2 is not in white list
        vm.expectRevert("only white list members can call this function.");
        vm.prank(user2);
        proxyfiatTokenV3.transfer(user1, transferAmount);
    }
}