//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {IRebaseToken} from "src/interfaces/IRabseToken.sol";
import {Vault} from "src/vault.sol";

contract RabaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        vm.deal(owner, 10 ether);
        rebaseToken = new RebaseToken();
        vault = new Vault(address(rebaseToken));
        rebaseToken.grandtMintAndBurnRole(address(vault));
        console.log("Vault Address:", address(vault));
        (bool success,) = payable(address(vault)).call{value: 10 ether}("");
        vm.stopPrank();
    }

    function addRewardToVault(uint256 _rewardAmount) public {
        (bool success,) = payable(address(vault)).call{value: _rewardAmount}("");
    }

    function testdepositLinear(uint256 _amount) public {
        _amount = bound(_amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, _amount);
        vault.deposit{value: _amount}();

        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("Start Balance:", startBalance);
        // assertEq(startBalance, _amount);
        vm.warp(block.timestamp + 1 hours);

        uint256 middleBalance = rebaseToken.balanceOf(user);
        console.log("Middle Balance:", middleBalance);
        assertGt(middleBalance, startBalance);

        vm.warp(block.timestamp + 1 hours);

        uint256 endBalance = rebaseToken.balanceOf(user);
        console.log("End Balance:", endBalance);
        assertGt(endBalance, middleBalance);
        vm.stopPrank();

        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);
    }

    function testRedeemStraightAway(uint256 _amount) public {
        _amount = bound(_amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, _amount);
        vault.deposit{value: _amount}();
        assertEq(rebaseToken.balanceOf(user), _amount);

        uint256 startBalance = rebaseToken.balanceOf(user);
        //     console.log("Start Balance:", startBalance);
        //     // assertEq(startBalance, _amount);
        //     vm.warp(block.timestamp + 1 hours);

        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, _amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) external {
        time = bound(time, 1000, 365 days);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        vm.prank(user);
        vm.deal(user, depositAmount);
        vault.deposit{value: depositAmount}();

        vm.warp(block.timestamp + time);
        uint256 balance = rebaseToken.balanceOf(user);

        vm.prank(owner);
        vm.deal(owner, balance - depositAmount);
        addRewardToVault(balance - depositAmount);

        vm.prank(user);
        vault.redeem(type(uint256).max);

        uint256 ethBalance = address(user).balance;

        assertEq(ethBalance, balance);
        assertGt(ethBalance, depositAmount);
    }

    function testTransfer(uint256 _amount, uint256 _amountToSend) public {
        _amount = bound(_amount, 1e5 + 1e5, type(uint96).max);
        _amountToSend = bound(_amountToSend, 1e5, _amount - 1e5);

        vm.prank(user);
        vm.deal(user, _amount);
        vault.deposit{value: _amount}();

        address user2 = makeAddr("user2");
        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 user2Balance = rebaseToken.balanceOf(user2);
        assertEq(userBalance, _amount);
        assertEq(user2Balance, 0);

        //2. owner reduced intrest rate to 4%
        vm.prank(owner);
        rebaseToken.setIntrestRate(4e10); // 4% annual interest

        //2. transfer from user1 to user2
        vm.prank(user);
        rebaseToken.transfer(user2, _amountToSend);
        uint256 userBalanceAfterTransfer = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTransfer = rebaseToken.balanceOf(user2);
        console.log("User1 Balance After Transfer:", userBalanceAfterTransfer);
        console.log("User2 Balance After Transfer:", user2BalanceAfterTransfer);

        assertEq(userBalanceAfterTransfer, userBalance - _amountToSend);
        assertEq(user2BalanceAfterTransfer, _amountToSend);

        //heck user rate is inherited
        assertEq(rebaseToken.getUserInterestRate(user2), rebaseToken.getUserInterestRate(user));
    }

    function testIntrestRateRevertnotOwner() external {
        vm.prank(user);
        vm.expectRevert();
        rebaseToken.setIntrestRate(5e10);
    }

    function testannotCallMintAndBurn() external {
        vm.prank(user);
        vm.expectRevert();
        rebaseToken.burn(user, 1000);

        vm.prank(user);

        vm.expectRevert();
        rebaseToken.mint(user, 1000, 5e10);
    }

    function testPrincipalBalance(uint256 _amount) public {
        _amount = bound(_amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, _amount);
        vault.deposit{value: _amount}();

        uint256 principalBalance = rebaseToken.principalBalanceOf(user);
        console.log("Principal Balance:", principalBalance);
        assertEq(principalBalance, _amount);

        vm.warp(block.timestamp + 30 days);

        uint256 principalBalanceAfterTime = rebaseToken.principalBalanceOf(user);
        console.log("Principal Balance After Time:", principalBalanceAfterTime);
        assertEq(principalBalanceAfterTime, _amount);

        vm.stopPrank();
    }

    function testGetRebaseTokenAddress() public {
        address rebaseTokenAddressFromVault = vault.getRebaseTokenAddress();
        assertEq(rebaseTokenAddressFromVault, address(rebaseToken));
    }
}
