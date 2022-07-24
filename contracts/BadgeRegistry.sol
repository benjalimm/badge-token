//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntityFactory.sol";
import "../interfaces/IBadgePriceOracle.sol";
import "../interfaces/IEntity.sol";
import "./CommonErrors.sol";

contract BadgeRegistry is IBadgeRegistry {
    string public constant VERSION = "1.0";

    // ** Enums ** \\
    enum EntityReverseRecordType {
        BadgeToken,
        PermissionToken
    }
    // ** EVENTS ** \\
    event EntityRegistered(
        address entityAddress,
        string entityName,
        address genesisTokenHolder,
        address permissionToken,
        address badgeToken
    );

    // ** Deployer properties ** \\
    address public deployer;
    address public requestedDeployer;

    // ** Pertinent addresses ** \\
    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;
    address public badgeXPToken;
    address public badgeTreasury;
    address public badgePriceOracle;
    address public recoveryOracle;

    // ** Registry info ** \\
    mapping(address => bool) public entities;
    mapping(address => bool) public certifiedRegistries;

    // ** ** \\
    uint256 public baseMinimumStake = 0.015 ether;

    constructor() {
        deployer = msg.sender;
        certifiedRegistries[address(this)] = true;
    }

    // ** Modifiers ** \\
    modifier deployerOnly() {
        if (msg.sender != deployer)
            revert Unauthorized("Only deployer can call this");
        _;
    }

    modifier registeredEntity() {
        if (entities[msg.sender] != true)
            revert Unauthorized("Entity not registered");
        _;
    }

    // ** Registry functions ** \\
    function registerEntity(
        string calldata entityName,
        string calldata genesisTokenURI,
        bool deployTokens
    ) external payable {
        // 1. Deploy entity
        IEntity entity = IEntityFactory(entityFactory).createEntity(
            entityName,
            recoveryOracle,
            msg.sender,
            genesisTokenURI,
            deployTokens
        );
        address entityAddress = address(entity);

        // 2. Set entity address in registry
        entities[entityAddress] = true;

        address badgeToken;
        address permToken;

        if (deployTokens) {
            // 3. Ensure there is enough ether to stake
            require(msg.value >= baseMinimumStake, "Not enough stake");

            badgeToken = entity.getBadgeToken();
            permToken = entity.getPermissionToken();

            (bool success, ) = badgeToken.call{value: msg.value}("");
            require(success, "Failed to send eth to badge token");
        }

        emit EntityRegistered(
            entityAddress,
            entityName,
            msg.sender,
            permToken,
            badgeToken
        );
    }

    // ** Getter methods ** \\

    function isRegistered(address addr) external view override returns (bool) {
        return entities[addr];
    }

    function getBadgePrice(uint8 level)
        external
        view
        override
        returns (uint256)
    {
        return IBadgePriceOracle(badgePriceOracle).calculateBadgePrice(level);
    }

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
        return badgeTreasury;
    }

    function getRecoveryOracle() external view override returns (address) {
        return recoveryOracle;
    }

    function isRegistryCertified(address _registry)
        external
        view
        override
        returns (bool)
    {
        return certifiedRegistries[_registry];
    }

    function getBaseMinimumStake() external view override returns (uint256) {
        return baseMinimumStake;
    }

    // ** Setter functions ** \\

    // ** Deployer set functions ** \\
    function setEntityFactory(address _entityFactory) external deployerOnly {
        entityFactory = _entityFactory;
    }

    function setBadgeTokenFactory(address _badgeTokenFactory)
        external
        deployerOnly
    {
        badgeTokenFactory = _badgeTokenFactory;
    }

    function setPermissionTokenFactory(address _permissionTokenFactory)
        external
        deployerOnly
    {
        permissionTokenFactory = _permissionTokenFactory;
    }

    function setBadgeXPToken(address _badgeXPToken) external deployerOnly {
        badgeXPToken = _badgeXPToken;
    }

    function setBadgePriceOracle(address _badgePriceOracle)
        external
        deployerOnly
    {
        badgePriceOracle = _badgePriceOracle;
    }

    function setRecoveryOracle(address _recoveryOracle) external deployerOnly {
        recoveryOracle = _recoveryOracle;
    }

    function setCertifiedRegistry(address _certifiedRegistry, bool _certified)
        external
        deployerOnly
    {
        certifiedRegistries[_certifiedRegistry] = _certified;
    }

    function setBaseMinimumStake(uint256 _baseMinimumStake)
        external
        deployerOnly
    {
        baseMinimumStake = _baseMinimumStake;
    }

    function setBadgeTreasury(address _badgeTreasury) external deployerOnly {
        badgeTreasury = _badgeTreasury;
    }

    // ** DEPLOYER MGMT METHODS ** \\
    function requestNewDeployer(address _requestedDeployer)
        external
        deployerOnly
    {
        requestedDeployer = _requestedDeployer;
    }

    function acceptDeployerRequest() external {
        require(msg.sender == requestedDeployer, "Not requested deployer");
        deployer = msg.sender;
    }

    function getDeployer() external view override returns (address) {
        return deployer;
    }
}
