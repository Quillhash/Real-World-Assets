// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { AAPL } from "../src/AAPL.sol";

contract DeployAAPL is Script {
    address public aaplFeed = 0x7E7B45b08F68EC69A99AAb12e42FcCB078e10094;
    address public ethUsdFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    function run() external returns (AAPL, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (address wethUsdPriceFeed, address weth, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        AAPL aapl = new AAPL(aaplFeed, ethUsdFeed);

        vm.stopBroadcast();
        return (aapl, helperConfig);
    }
}