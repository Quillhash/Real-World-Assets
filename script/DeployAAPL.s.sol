// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { AAPL } from "../src/AAPL.sol";

contract DeployAAPL is Script {
    function run() external {
        // Get params
        (address aaplFeed, address ethFeed, uint256 deployerKey) = getAaplRequirements();

        // Actually deploy
        vm.startBroadcast(deployerKey);
        deployAAPL(aaplFeed, ethFeed);
        vm.stopBroadcast();
    }

    function getAaplRequirements() public returns (address, address, uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (address ethFeed, address aaplFeed, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        if (aaplFeed == address(0) || ethFeed == address(0)) {
            revert("something is wrong");
        }
        return (aaplFeed, ethFeed, deployerKey);
    }

    function deployAAPL(address aaplFeed, address ethFeed) public returns (AAPL) {
        return new AAPL(aaplFeed, ethFeed);
    }
}
