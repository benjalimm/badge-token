//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "../interfaces/IBadgePriceCalculator.sol";

contract BadgePriceCalculator is IBadgePriceCalculator {
    uint256 public baseBadgePrice = 2649000000000000;
    uint256 public levelMultiplierX1000 = 2500;

    function calculateBadgePrice(uint256 level)
        external
        view
        returns (uint256)
    {
        if (level > 0) {
            return
                baseBadgePrice *
                ((levelMultiplierX1000 ^ (level - 1)) / (1000 ^ (level - 1)));
        }
        return 0;
    }
}
