//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {
    IERC20
} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {Pool} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {RebaseToken} from "./RebaseToken.sol";

contract RebaseTokenPool is TokenPool {
    RebaseToken private immutable i_rebaseToken;

    constructor(
        IERC20 _token,
        address[] memory _allowList,
        address _rmnProxy,
        address _router,
        address _rebaseTokenAddress
    ) TokenPool(_token, 18, _allowList, _rmnProxy, _router) {
        i_rebaseToken = RebaseToken(_rebaseTokenAddress);
    }

    // if we sending to another chain,lock or burn will be called by ccip

    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    ) external returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut) {
        //we have to call this function to validate the lock or burn input; so data notting supiious is haping: ask ai or read docs
        _validateLockOrBurn(lockOrBurnIn);
        address originalSender = abi.decode(lockOrBurnIn.originalSender, (address));
        uint256 userInterestRate = i_rebaseToken.getUserInterestRate(originalSender);
    i_rebaseToken.burn(
        address(this),
        lockOrBurnIn.amount
    );

lockOrBurnOut = Pool.LockOrBurnOutV1({
    //destination address eng abtrum adress, the getremoteToken will handle it bas on what we set
           destTokenAddress : getRemoteToken(lockOrBurnIn.remoteChainSelector), 
            destPoolData: abi.encode(userInterestRate)      
        
        });


    }

    // if we receiving from another chain, release or mint will be called by ccip
    //and lock or burn in the chain
    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory releaseOrMintOut) {


_validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));

i_rebaseToken.mint(releaseOrMintIn.receiver, releaseOrMintIn.amount,userInterestRate);

       return Pool.ReleaseOrMintOutV1({
        destinationAmount : releaseOrMintIn.amount
       });
    }
}
