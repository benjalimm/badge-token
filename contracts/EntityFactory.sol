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

    function createEntity(
        string calldata entityName,
        address genesisUser,
        string calldata genesisTokenURI
    ) external override badgeRegistryOnly returns (address) {
        address entityAddress = address(new Entity(entityName, badgeRegistry));
        emit EntityDeployed(entityName, entityAddress);
        return entityAddress;
    }
}
