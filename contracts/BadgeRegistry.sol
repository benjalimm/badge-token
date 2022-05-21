//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntityFactory.sol";
import "../interfaces/IBadgePriceCalculator.sol";

contract BadgeRegistry is IBadgeRegistry {
    mapping(address => bool) public entities;
    address public permissionContract;
    uint256 public baseBadgePrice = 2649000000000000;
    uint256 public levelMultiplierX1000 = 2500;
    address public owner;

    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;
    address public badgeXPToken;
    address public badgeGnosisSafe = address(0);
    address public badgePriceCalculator;

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

    function getBadgePrice(uint256 level)
        external
        view
        override
        returns (uint256)
    {
        return
            IBadgePriceCalculator(badgePriceCalculator).calculateBadgePrice(
                level
            );
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

    function getSafe() external view override returns (address) {
        return badgeGnosisSafe;
    }

    function getLevelMultiplierX1000()
        external
        view
        override
        returns (uint256)
    {
        return levelMultiplierX1000;
    }

    function setEntityFactory(address _entityFactory)
        external
        override
        ownerOnly
    {
        entityFactory = _entityFactory;
        emit EntityFactorySet(_entityFactory);
    }

    function setBadgeTokenFactory(address _badgeTokenFactory)
        external
        override
        ownerOnly
    {
        badgeTokenFactory = _badgeTokenFactory;
        emit BadgeTokenFactorySet(_badgeTokenFactory);
    }

    function setPermissionTokenFactory(address _permissionTokenFactory)
        external
        override
        ownerOnly
    {
        permissionTokenFactory = _permissionTokenFactory;
        emit PermissionTokenFactorySet(_permissionTokenFactory);
    }

    function setBadgeXPToken(address _badgeXPToken)
        external
        override
        ownerOnly
    {
        badgeXPToken = _badgeXPToken;
        emit BadgeXPTokenSet(_badgeXPToken);
    }

    function setBadgePriceCalculator(address _badgePriceCalculator)
        external
        override
        ownerOnly
    {
        badgePriceCalculator = _badgePriceCalculator;
        emit BadgePriceCalculatorSet(badgePriceCalculator);
    }
}
