pragma solidity ^0.8.0;

interface IBadgeTokenFactory {
    function createBadgeToken(string calldata _entityName)
        external
        returns (address);
}