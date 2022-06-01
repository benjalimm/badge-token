pragma solidity ^0.8.0;

interface IBadgeTokenFactory {
    function createBadgeToken(
        string calldata _entityName,
        address recoveryOracle
    ) external returns (address);

    event BadgeTokenDeployed(
        string entityName,
        address entityAddress,
        address contractAddress
    );
}
