//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";

contract BadgeRegistry {
    mapping(address => string) public entities;

    constructor() {
        console.log("Successfully deployed");
    }

    function deployEntity(string calldata name, string calldata genesisTokenURI)
        external
        payable
    {
        Entity e = new Entity(name, genesisTokenURI);
        entities[address(e)] = name;
    }
}
