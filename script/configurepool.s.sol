//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

import {Script} from "forge-std/Script.sol";

contract ConfigurePoolScript is Script {
    function run(
        address localPool,
        uint64 remotechainSelector,
        address remotePool,
        address remoteTokenAddress,
        bool outboundRateLimiterIsEnabled,
        uint128 outboundRateLimiterCapacity,
        uint128 outboundRateLimiterRate,
        bool inboundRateLimiterIsEnabled,
        uint128 inboundRateLimiterCapacity,
        uint128 inboundRateLimiterRate
    ) public {
        vm.startBroadcast();

        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);

        TokenPool.ChainUpdate[] memory chainToAdd = new TokenPool.ChainUpdate[](1);

        chainToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remotechainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: outboundRateLimiterIsEnabled,
                capacity: outboundRateLimiterCapacity,
                rate: outboundRateLimiterRate
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: inboundRateLimiterIsEnabled,
                capacity: inboundRateLimiterCapacity,
                rate: inboundRateLimiterRate
            })
        });
        TokenPool(localPool).applyChainUpdates(new uint64[](0), chainToAdd);

        vm.startBroadcast();
    }
}
