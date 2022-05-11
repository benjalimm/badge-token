//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "./Entity.sol";
import "../interfaces/IEntityFactory.sol";

contract EntityFactory is IEntityFactory {
    address public badgeRegistry;

    constructor(address _badgeRegistry) {
        badgeRegistry = _badgeRegistry;
    }

    modifier badgeRegistryOnly() {
        require(
            msg.sender == badgeRegistry,
            "Only badge registry can call this"
        );
        _;
    }

    function createEntity(string calldata _entityName)
        external
        override
        badgeRegistryOnly
        returns (address)
    {
        return address(new Entity(_entityName, badgeRegistry));
    }
}
