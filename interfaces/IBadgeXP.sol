pragma solidity ^0.8.4;

interface IBadgeXP {
    error Unauthorized(string message);
    error Failure(string message);

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
