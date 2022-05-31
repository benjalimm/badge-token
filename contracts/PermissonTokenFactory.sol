pragma solidity ^0.8.0;

import "./PermissionToken.sol";
import "../interfaces/IPermissionTokenFactory.sol";

contract PermissionTokenFactory is IPermissionTokenFactory {
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
