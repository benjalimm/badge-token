pragma solidity ^0.8.4;

interface IBadgePriceCalculator {
    function calculateBadgePrice(uint256 level) external view returns (uint256);
}
