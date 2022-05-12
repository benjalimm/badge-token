pragma solidity ^0.8.0;

interface IBadgeXP {
    function mint(uint256 amount, address recipient) external;

    function burn(uint256 amount, address recipient) external;
}
