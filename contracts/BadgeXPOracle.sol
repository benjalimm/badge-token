pragma solidity ^0.8.4;
import "../interfaces/IBadgeXPOracle.sol";

contract BadgeXPOracle is IBadgeXPOracle {
    string public constant VERSION = "1.0";
    uint256 constant baseXP = 1000;

    function calculateXP(uint256 level)
        external
        pure
        override
        returns (uint256)
    {
        if (level > 0) {
            uint256 xp = 0;

            for (uint256 i = level; i > 0; i--) {
                xp += baseXP + ((25 * xp) / 100);
            }
            return xp;
        } else {
            return 0;
        }
    }
}
