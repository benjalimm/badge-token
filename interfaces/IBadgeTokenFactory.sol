pragma solidity ^0.8.4;

interface IBadgeTokenFactory {
    function createBadgeToken(
        string calldata _entityName,
        address recoveryOracle
    ) external returns (address);
}
