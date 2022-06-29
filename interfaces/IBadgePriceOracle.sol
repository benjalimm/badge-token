pragma solidity ^0.8.4;

interface IBadgePriceOracle {
    function calculateBadgePrice(uint8 level) external view returns (uint256);
}
