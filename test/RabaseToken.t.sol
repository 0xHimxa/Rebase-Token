//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
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




  function testdepositLinear(uint256 _amount) public{
    _amount = bound(_amount,1e5,type(uint96).max);
    vm.startPrank(user);
    vm.deal(user, _amount);
    vault.deposit{value: _amount}();

    uint256 startBalance = rebaseToken.balanceOf(user);
    console.log("Start Balance:", startBalance);
    // assertEq(startBalance, _amount);
    vm.warp(block.timestamp + 1 days);

    uint256 middleBalance = rebaseToken.balanceOf(user);
    console.log("Middle Balance:", middleBalance);
    assertGt(middleBalance, startBalance);


    vm.warp(block.timestamp + 1 days);


    uint256 endBalance = rebaseToken.balanceOf(user);
    console.log("End Balance:", endBalance);
    assertGt(endBalance, middleBalance);
    vm.stopPrank();

    assertApproxEqAbs(endBalance - middleBalance, middleBalance- startBalance,1 );

  }  
}