//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "../interfaces/IBadgePriceOracle.sol";
import "../interfaces/IBadgeRegistry.sol";

contract BadgePriceOracle is IBadgePriceOracle {
    string public constant version = "1.0";

    uint256 public baseBadgePrice = 0.0035 ether;
    uint256 public levelMultiplierX100 = 250; // Represents 2.5x

    address public badgeRegistry;

    constructor(address _badgeRegistry) {
        badgeRegistry = _badgeRegistry;
    }

    function pow(uint256 n, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return n;
        } else {
            uint256 p = pow(n, e / 2);
            p = p * p;
            if (e % 2 == 1) {
                p = p * n;
            }
            return p;
        }
    }

    function calculateBadgePrice(uint8 level)
        external
        view
        override
        returns (uint256)
    {
        if (level == 1) {
            return baseBadgePrice;
        } else if (level > 1) {
            return
                ((baseBadgePrice / 10) *
                    pow(levelMultiplierX100, (level - 1))) /
                (pow(100, (level - 1)) / 10);
        } else {
            return 0;
        }
    }

    function setBaseBadgePrice(uint256 price) external {
        address deployer = IBadgeRegistry(badgeRegistry).getDeployer();
        require(msg.sender == deployer, "Deployer only");
        baseBadgePrice = price;
    }
}
