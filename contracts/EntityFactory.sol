//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./Entity.sol";
import "../interfaces/IEntityFactory.sol";

contract EntityFactory is IEntityFactory {
    // ** Events ** \\
    event EntityDeployed(string entityName, address entityAddress);
    
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
        address recoveryOracle,
        address genesisUser,
        string calldata genesisTokenURI,
        bool deployTokens
    ) external override badgeRegistryOnly returns (IEntity) {
        IEntity entity = new Entity(
            entityName,
            badgeRegistry,
            recoveryOracle,
            genesisUser,
            genesisTokenURI,
            deployTokens
        );
        emit EntityDeployed(entityName, address(entity));
        return entity;
    }
}
