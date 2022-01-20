//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";

contract BadgeRegistry {
    address[] public entities;

    constructor() {
        console.log("Successfully deployed");
    }

    function deployEntity(
        string memory entityName,
        string memory genesisTokenURI
    ) external payable returns (Entity) {
        Entity entity = new Entity(entityName, genesisTokenURI);
        entities.push(address(entity));
        return entity;
    }
}
