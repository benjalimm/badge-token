//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Entity.sol";
import "./GenesisToken.sol";
import "./SuperUserToken.sol";
import "./BasicUserToken.sol";

contract BadgeV1 {
    address[] public entities;
    GenesisToken public genesisToken;
    SuperUserToken public superUserToken;
    BasicUserToken public basicUserToken;

    constructor() {
        genesisToken = new GenesisToken();
        superUserToken = new SuperUserToken();
        basicUserToken = new BasicUserToken();
        console.log("Succesfully deployed");
    }

    function deployEntity(string memory entityName)
        public
        payable
        returns (Entity)
    {
        Entity entity = new Entity(entityName);
        entities.push(address(entity));
        return entity;
    }
}
