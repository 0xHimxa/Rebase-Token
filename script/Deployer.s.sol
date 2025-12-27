//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/vault.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {CCIPLocalSimulatorFork, Register} from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {
    RegistryModuleOwnerCustom
} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";

import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract TokenAndPoolDeployer is Script {
    function run() public returns (RebaseToken rebaseToken, RebaseTokenPool rebaseTokenPool) {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory networkDetaials = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startBroadcast();
        rebaseToken = new RebaseToken();
        rebaseTokenPool = new RebaseTokenPool(
            IERC20(address(rebaseToken)),
            new address[](0),
            networkDetaials.rmnProxyAddress,
            networkDetaials.routerAddress,
            address(rebaseToken)
        );

        rebaseToken.grandtMintAndBurnRole(address(rebaseTokenPool));
        RegistryModuleOwnerCustom(networkDetaials.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(rebaseToken));

        TokenAdminRegistry(networkDetaials.tokenAdminRegistryAddress).acceptAdminRole(address(rebaseToken));
        TokenAdminRegistry(networkDetaials.tokenAdminRegistryAddress)
            .setPool(address(rebaseToken), address(rebaseTokenPool));

        vm.stopBroadcast();
    }
}

contract DeployVault is Script {
    function run(RebaseToken _rebaseToken) public returns (Vault vault) {
        vm.startBroadcast();
        Vault vault = new Vault(address(_rebaseToken));
        _rebaseToken.grandtMintAndBurnRole(address(vault));

        vm.stopBroadcast();
    }
}
