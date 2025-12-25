//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/vault.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {CCIPLocalSimulatorFork} from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";

contract CrossChainTest is Test {
    RebaseToken  sepoliaToken;
    RebaseToken  arbSepoliaToken;
    RebaseTokenPool private rebaseTokenPool;
    Vault private vault;
    uint256 private sepoliaFork;
    uint256 private arbSepoliaFork;
    CCIPLocalSimulatorFork private ccipLocalSimulatorFork;

 address owner = makeAddr('owner');
function setUp() external{
    // here we will deploy the contracts on sepolia fork
    sepoliaFork = vm.createFork(vm.rpcUrl("sepolia_eth"));
    arbSepoliaFork = vm.createFork(vm.rpcUrl("arb_sepolia"));
    
//    sepoliaFork = vm.createFork(("sepolia_eth");
   // sepoliaFork = vm.createFork("sepolia_eth");
     

// now we need to create a way to send cross chain
    ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
//now we need a wait to make the local for add presitsnt

vm.makePersistent(address(ccipLocalSimulatorFork));


// below we deply it on two chain

//deploy and configure contracts on sepolia fork
vm.startPrank(owner);
sepoliaToken  = mew RebaseToken();

//we only deploy vault on sepolia, it our soure chain
vault = new Vault(address(sepoliaToken));
vm.stopPrank();

//2nd switch to arb sepolia fork and deploy and configure contracts there
vm.selectFork(arbSepoliaFork);
vm.startPrank(owner);
arbSepoliaToken  = new RebaseToken();
vm.stopPrank();

   

}


}
