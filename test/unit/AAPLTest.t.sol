// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {DeployAAPL} from "../../script/DeployAAPL.s.sol";
import {AAPL} from "../../src/AAPL.sol";

contract AAPLTest is Test {
    DeployAAPL deployAAPL;
    AAPL aapl;
    address public user = makeAddr("user");
    uint256 constant STARTING_ETH_BALANCE = 100e18;

    function setUp() public {
        deployAAPL = new DeployAAPL();
        (address aaplFeed, address ethFeed, ) = deployAAPL.getAaplRequirements();
        aapl = deployAAPL.deployAAPL(aaplFeed, ethFeed);
    }

    function testDeployAAPL() public {
        deployAAPL.run();
    }

    function testCanMintAapl() public {
        vm.deal(user, STARTING_ETH_BALANCE);
        vm.prank(user);
        aapl.depositAndmint{ value: 10e18 }(1e18);

        assertEq(aapl.balanceOf(user), 1e18);
    }

    function testCanRedeem() public {
        vm.deal(user, STARTING_ETH_BALANCE);
        vm.startPrank(user);
        aapl.depositAndmint{ value: 10e18 }(1e18);
        aapl.approve(address(aapl), 1e18);
        aapl.redeemAndBurn(1e18);
        vm.stopPrank();
        assertEq(aapl.balanceOf(user), 0);
    }
}
