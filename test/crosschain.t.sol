//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/vault.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {CCIPLocalSimulatorFork, Register} from "lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

import {
    RegistryModuleOwnerCustom
} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {Client} from "lib/ccip/contracts/src/v0.8/Client.sol";

import {RateLimiter} from "lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
//register is a  store struct that contains the roter,selector and cip test token addree
//click the file for more info

//note in the register file they have all ready set all the chainlink ccip local simulator details for sepolia and arb sepolia

contract CrossChainTest is Test {
    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;
    RebaseTokenPool private rebaseTokenPool;
    Vault private vault;
    uint256 private sepoliaFork;
    uint256 private arbSepoliaFork;
    CCIPLocalSimulatorFork private ccipLocalSimulatorFork;
    RebaseTokenPool sepoliaPool;
    RebaseTokenPool arbSepoliaPool;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;

    address owner = makeAddr("owner");

    function setUp() external {
        // here we will deploy the contracts on sepolia fork
        sepoliaFork = vm.createFork(vm.rpcUrl("sepolia_eth"));
        arbSepoliaFork = vm.createFork(vm.rpcUrl("arb_sepolia"));
        console.log("sepolia fork id:", sepoliaFork);
        //    sepoliaFork = vm.createFork(("sepolia_eth");
        // sepoliaFork = vm.createFork("sepolia_eth");

        // now we need to create a way to send cross chain
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        //now we need a wait to make the local for add presitsnt

        vm.makePersistent(address(ccipLocalSimulatorFork));

        // below we deply it on two chain

        //deploy and configure contracts on sepolia fork

        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();

        //we only deploy vault on sepolia, it our soure chain
        vault = new Vault(address(sepoliaToken));
        sepoliaPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)),
            new address[](0),
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress,
            address(sepoliaToken)
        );

        sepoliaToken.grandtMintAndBurnRole(address(vault));
        sepoliaToken.grandtMintAndBurnRole(address(sepoliaPool));

        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress)
            .setPool(address(sepoliaToken), address(sepoliaPool));

        vm.stopPrank();

        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        //2nd switch to arb sepolia fork and deploy and configure contracts there
        vm.selectFork(arbSepoliaFork);
        vm.startPrank(owner);
        arbSepoliaToken = new RebaseToken();

        arbSepoliaPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)),
            new address[](0),
            arbSepoliaNetworkDetails.rmnProxyAddress,
            arbSepoliaNetworkDetails.routerAddress,
            address(arbSepoliaToken)
        );

        arbSepoliaToken.grandtMintAndBurnRole(address(arbSepoliaPool));
        arbSepoliaToken.grandtMintAndBurnRole(address(vault));

        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(arbSepoliaToken));

        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .setPool(address(arbSepoliaToken), address(arbSepoliaPool));

        configureTokenPool(
            sepoliaFork,
            address(sepoliaPool),
            arbSepoliaNetworkDetails.chainSelector,
            address(arbSepoliaPool),
            address(arbSepoliaToken)
        );

        configureTokenPool(
            arbSepoliaFork,
            address(arbSepoliaPool),
            sepoliaNetworkDetails.chainSelector,
            address(sepoliaPool),
            address(sepoliaToken)
        );

        vm.stopPrank();
    }

    //if daubting check out the ccp files

    function configureTokenPool(
        uint256 fork,
        address localPool,
        uint64 remotechainSelector,
        address remotePool,
        address remoteTokenAddress
    ) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);

        TokenPool.ChainUpdate[] memory chainToAdd = new TokenPool.ChainUpdate[](1);

        chainToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remotechainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });

        vm.stopPrank();
    }

    //the chain we are briging from is the local

    function bridgeTokens(
        uint256 amountToBridge,
        uint256 localFork,
        uint256 remoteFork,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        RebaseToken localToken,
        RebaseToken remoteToken
    ) public {
        vm.selectFork(localFork);
        vm.startPrank(owner);
    }
}
