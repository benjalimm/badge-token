pragma solidity ^0.8.4;

import "./PermissionToken.sol";
import "../interfaces/IPermissionTokenFactory.sol";

contract PermissionTokenFactory is IPermissionTokenFactory {
    event PermissionTokenDeployed(string entityName, address entityAddress);

    address public badgeRegistry;

    function createPermissionToken(string calldata _entityName)
        external
        override
        returns (address)
    {
        address tokenAddress = address(
            new PermissionToken(_entityName, msg.sender)
        );
        emit PermissionTokenDeployed(_entityName, tokenAddress);
        return tokenAddress;
    }
}
