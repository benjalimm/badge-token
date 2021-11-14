//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./PermissionToken.sol";
import "./Entity.sol";

contract BadgeV1 {
    address[] public entities;

    function deployEntity(string memory entityName)
        public
        payable
        returns (address)
    {
        Entity entity = new Entity(entityName);
        entities.push(entity);
        return entity;
    }
}
