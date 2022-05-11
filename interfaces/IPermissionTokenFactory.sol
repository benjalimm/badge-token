pragma solidity ^0.8.0;

interface IPermissionTokenFactory {
    function createPermissionToken(
        string calldata _entityName,
        string calldata _genTokenURI
    ) external returns (address);
}
