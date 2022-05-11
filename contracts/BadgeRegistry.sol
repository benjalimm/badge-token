//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntityFactory.sol";

contract BadgeRegistry is IBadgeRegistry {
    mapping(address => bool) public entities;
    address public permissionContract;
    uint256 public badgePrice = 5;
    uint256 public levelMultiplier = 2;
    address public owner;

    //Factory address
    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;

    constructor() {
        owner = msg.sender;
    }

    function registerEntity(string calldata _entityName) external override {
        address entityAddress = IEntityFactory(entityFactory).createEntity(
            _entityName
        );
        entities[entityAddress] = true;
        emit EntityRegistered(entityAddress);
    }

    function isRegistered(address addr) external view override returns (bool) {
        return entities[addr];
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function getBadgePrice(uint256 level) external view returns (uint256) {
        return badgePrice * (levelMultiplier ^ level);
    }

    //Get methods
    function getBadgeTokenFactory() external view override returns (address) {
        return badgeTokenFactory;
    }

    function getEntityFactory() external view override returns (address) {
        return entityFactory;
    }

    function getPermissionTokenFactory()
        external
        view
        override
        returns (address)
    {
        return permissionTokenFactory;
    }

    /// Owner only methods
    function setBadgePrice(uint256 _price) external ownerOnly {
        badgePrice = _price;
    }

    function setEntityFactory(address _entityFactory) external ownerOnly {
        entityFactory = _entityFactory;
    }
}
