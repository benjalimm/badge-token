pragma solidity ^0.8.0;

interface IBadgePriceCalculator {
    function calculateBadgePrice(uint256 level) external view returns (uint256);
}
