pragma solidity ^0.8.0;

interface IPermissionTokenFactory {
    function createPermissionToken(string calldata _entityName)
        external
        returns (address);
}
