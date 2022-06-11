pragma solidity ^0.8.4;

interface IBadgeXPOracle {
    function calculateXP(uint256 level) external pure returns (uint256);
}
