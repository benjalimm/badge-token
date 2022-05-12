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
    uint256 public baseBadgePrice = 2655352639536000; // $5 in ETH
    uint256 public levelMultiplierX1000 = 2500;
    address public owner;

    //Factory address
    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;
    address public badgeXPToken;

    constructor() {
        owner = msg.sender;
    }

    function registerEntity(
        string calldata entityName,
        string calldata genesisTokenURI
    ) external override {
        address entityAddress = IEntityFactory(entityFactory).createEntity(
            entityName,
            msg.sender,
            genesisTokenURI
        );
        entities[entityAddress] = true;
        emit EntityRegistered(entityAddress, entityName, msg.sender);
    }

    function isRegistered(address addr) external view override returns (bool) {
        return entities[addr];
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function getBadgePrice(uint256 level) external view returns (uint256) {
        return
            baseBadgePrice * ((levelMultiplierX1000 ^ level) / (1000 ^ level));
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

    function getBadgeXPToken() external view override returns (address) {
        return badgeXPToken;
    }

    /// Owner only methods
    function setBadgePrice(uint256 _price) external ownerOnly {
        baseBadgePrice = _price;
    }

    function setEntityFactory(address _entityFactory) external ownerOnly {
        entityFactory = _entityFactory;
    }

    function setBadgeTokenFactory(address _badgeTokenFactory)
        external
        ownerOnly
    {
        badgeTokenFactory = _badgeTokenFactory;
    }

    function setPermissionTokenFactory(address _permissionTokenFactory)
        external
        ownerOnly
    {
        permissionTokenFactory = _permissionTokenFactory;
    }

    function setBadgeXPToken(address _badgeXPToken) external ownerOnly {
        badgeXPToken = _badgeXPToken;
    }
}
