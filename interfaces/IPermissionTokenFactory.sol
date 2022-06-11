pragma solidity ^0.8.4;

interface IPermissionTokenFactory {
    function createPermissionToken(string calldata _entityName)
        external
        returns (address);

    event PermissionTokenDeployed(string entityName, address entityAddress);
}
