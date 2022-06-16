pragma solidity ^0.8.4;

interface IBadgeXP {
    function mint(
        uint256 level,
        address recipient,
        address registry
    ) external;

    function burn(
        uint256 amount,
        address recipient,
        address registry
    ) external;
}
