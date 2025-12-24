//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

 import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pool} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
 contract RebaseTokenPool is TokenPool {
     constructor(IERC20 _token,address[] memory _allowList ,address _rmnProxy, address _router) TokenPool(_token,18,_allowList,_rmnProxy,_router) {}




 }
 