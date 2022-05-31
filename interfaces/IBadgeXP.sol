pragma solidity ^0.8.0;

interface IBadgeXP {
    error Unauthorized(string message);

    function mint(uint256 level, address recipient) external;

    function burn(uint256 amount, address recipient) external;
}
