// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";
import { Script } from "forge-std/Script.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    MockV3Aggregator public aaplFeedMock;
    MockV3Aggregator public ethUsdFeedMock;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;

    struct NetworkConfig {
        address ethUsdPriceFeed;
        address aaplPriceFeed;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if(block.chainid == 137) {
            activeNetworkConfig = getPolygonConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getPolygonConfig() internal view returns (NetworkConfig memory config) {
        config = NetworkConfig({
            ethUsdPriceFeed: 0xF9680D99D6C9589e2a93a78A04A279e509205945,
            aaplPriceFeed: 0x7E7B45b08F68EC69A99AAb12e42FcCB078e10094,
            deployerKey: vm.envUint("PRIVATE_KEY")
         });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.ethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        aaplFeedMock = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ethUsdFeedMock = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            ethUsdPriceFeed: address(ethUsdFeedMock), // ETH / USD
            aaplPriceFeed: address(aaplFeedMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
