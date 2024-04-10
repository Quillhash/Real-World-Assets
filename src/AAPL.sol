// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/*
 * @title AAPL.sol (Tokenisation of Apple shares)
 * @author Prathmesh Ranjan
 * 
 * This is a token each representing an Apple share with the properties:
 * - Exogenously Collateralized
 * - Apple Share Pegged
 * - Algorithmically Stable
 *
 *
 * Our system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the AAPL.
 *
 * @dev the codebase will mint AAPL based on the collateral 
 * deposited into this contract. In this example, ETH is the
 * collateral that we will use to mint AAPL.
 */

contract AAPL is ERC20 {
    using OracleLib for AggregatorV3Interface;

    error AAPL_feeds__InsufficientCollateral();

    // These both have 8 decimal places for Polygon
    // https://docs.chain.link/data-feeds/price-feeds/addresses?network=polygon
    address private i_aaplFeed;
    address private i_ethUsdFeed;
    uint256 public constant DECIMALS = 8;
    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 public constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    mapping(address user => uint256 aaplMinted) public s_aaplMintedPerUser;
    mapping(address user => uint256 ethCollateral) public s_ethCollateralPerUser;

    constructor(address aaplFeed, address ethUsdFeed) ERC20("Synthetic Apple", "AAPL") {
        i_aaplFeed = aaplFeed;
        i_ethUsdFeed = ethUsdFeed;
    }

    /* 
     * @dev User must deposit at least 200% of the value of the AAPL they want to mint
     */
    
    function depositAndmint(uint256 amountToMint) external payable {
        // Checks / Effects
        s_ethCollateralPerUser[msg.sender] += msg.value;
        s_aaplMintedPerUser[msg.sender] += amountToMint;

        uint256 healthFactor = getHealthFactor(msg.sender);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert AAPL_feeds__InsufficientCollateral();
        }
        _mint(msg.sender, amountToMint);
    }

    function redeemAndBurn(uint256 amountToRedeem) external {
        // Checks / Effects
        uint256 valueRedeemed = getUsdAmountFromaapl(amountToRedeem);
        uint256 ethToReturn = getEthAmountFromUsd(valueRedeemed);
        s_aaplMintedPerUser[msg.sender] -= amountToRedeem;
        uint256 healthFactor = getHealthFactor(msg.sender);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert AAPL_feeds__InsufficientCollateral();
        }
        _burn(msg.sender, amountToRedeem);

        (bool success,) = msg.sender.call{value: ethToReturn}("");
        if (!success) {
            revert("AAPL_feeds: transfer failed");
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getHealthFactor(address user) public view returns (uint256) {
        (uint256 totalaaplMintedValueInUsd, uint256 totalCollateralEthValueInUsd) = getAccountInformationValue(user);
        return _calculateHealthFactor(totalaaplMintedValueInUsd, totalCollateralEthValueInUsd);
    }

    function getUsdAmountFromaapl(uint256 amountaaplInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_aaplFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (amountaaplInWei * (uint256(price) * ADDITIONAL_FEED_PRECISION)) / PRECISION;
    }

    function getUsdAmountFromEth(uint256 ethAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_ethUsdFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (ethAmountInWei * (uint256(price) * ADDITIONAL_FEED_PRECISION)) / PRECISION;
    }

    function getEthAmountFromUsd(uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_ethUsdFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (usdAmountInWei * PRECISION) / ((uint256(price) * ADDITIONAL_FEED_PRECISION) * PRECISION);
    }

    function getAccountInformationValue(address user)
        public
        view
        returns (uint256 totalaaplMintedValueUsd, uint256 totalCollateralValueUsd)
    {
        (uint256 totalaaplMinted, uint256 totalCollateralEth) = _getAccountInformation(user);
        totalaaplMintedValueUsd = getUsdAmountFromaapl(totalaaplMinted);
        totalCollateralValueUsd = getUsdAmountFromEth(totalCollateralEth);
    }

    function _calculateHealthFactor(uint256 aaplMintedValueUsd, uint256 collateralValueUsd)
        internal
        pure
        returns (uint256)
    {
        if (aaplMintedValueUsd == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / aaplMintedValueUsd;
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalaaplMinted, uint256 totalCollateralEth)
    {
        totalaaplMinted = s_aaplMintedPerUser[user];
        totalCollateralEth = s_ethCollateralPerUser[user];
    }
}