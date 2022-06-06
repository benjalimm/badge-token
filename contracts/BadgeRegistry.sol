//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntityFactory.sol";
import "../interfaces/IBadgePriceCalculator.sol";
import "../interfaces/IEntity.sol";

contract BadgeRegistry is IBadgeRegistry {
    uint256 public levelMultiplierX1000 = 2500;
    address public deployer;

    // ** Pertinent addresses ** \\
    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;
    address public badgeXPToken;
    address public badgeGnosisSafe = address(0);
    address public badgePriceCalculator;
    address public recoveryOracle;

    // ** Registry info ** \\
    mapping(address => bool) public entities;
    mapping(address => address) public badgeTokenEntityReverseRecord;
    mapping(address => address) public permTokenEntityReverseRecord;
    mapping(address => bool) public certifiedRegistries;

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

    // ** Registry functions ** \\
    function registerEntity(
        string calldata entityName,
        string calldata genesisTokenURI
    ) external override {
        // 1. Deploy entity
        IEntity entity = IEntityFactory(entityFactory).createEntity(
            entityName,
            recoveryOracle,
            msg.sender,
            genesisTokenURI
        );
        address entityAddress = address(entity);

        // 2. Set entity address in registry
        entities[entityAddress] = true;

        // 3. Store badge token reverse record
        badgeTokenEntityReverseRecord[entityAddress] = entity.getBadgeToken();

        // 4. Store permission token reverse record
        permTokenEntityReverseRecord[entityAddress] = entity
            .getPermissionToken();

        // 5. Emit entity registered
        emit EntityRegistered(entityAddress, entityName, msg.sender);
    }

    /**
     * Figure out which addresses are permission contracts
     * @param addresses List of contract addresses to filter through
     * @param tokenType Type of reverse record to filtler through (Badge token or Permission token)
     * @return filteredAddresses Addresses that exist in the reverse record. Returned as an array fixed to their origianl index in the list.
     */

    function filterAddressesForEntityReverseRecord(
        EntityReverseRecordType tokenType,
        address[] calldata addresses
    ) external view returns (address[] memory) {
        // 1. Select the correct reverse record
        mapping(address => address) storage reverseRecord = tokenType ==
            EntityReverseRecordType.BadgeToken
            ? badgeTokenEntityReverseRecord
            : permTokenEntityReverseRecord;

        address[] memory result = new address[](addresses.length);

        // 2. Loop through addresses for filtering
        uint256 i = 0;
        for (i = i; i < addresses.length; i++) {
            address addr = addresses[i];
            address entityAddress = reverseRecord[addr];

            // 3. If reverse record exists, add to result
            if (entities[entityAddress]) {
                result[i] = addr;
            }
        }
        return result;
    }

    // ** Getter methods ** \\

    function isRegistered(address addr) external view override returns (bool) {
        return entities[addr];
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

    function setBadgePriceCalculator(address _badgePriceCalculator)
        external
        deployerOnly
    {
        badgePriceCalculator = _badgePriceCalculator;
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
}
