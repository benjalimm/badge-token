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
    // ** Enums ** \\
    enum EntityReverseRecordType {
        BadgeToken,
        PermissionToken
    }
    // ** Events ** \\
    event EntityRegistered(
        address entityAddress,
        string entityName,
        address genesisTokenHolder,
        address permissionToken,
        address badgeToken
    );

    // ** Pertinent addresses ** \\
    address public deployer;
    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;
    address public badgeXPToken;
    address public badgeGnosisSafe = address(0);
    address public badgePriceOracle;
    address public recoveryOracle;

    // ** Registry info ** \\
    mapping(address => bool) public entities;
    mapping(address => address) public badgeTokenEntityReverseRecord;
    mapping(address => address) public permTokenEntityReverseRecord;
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

            // 4. Store badge token reverse record
            badgeTokenEntityReverseRecord[badgeToken] = entityAddress;

            // 5. Store permission token reverse record
            permTokenEntityReverseRecord[permToken] = entityAddress;
        }

        emit EntityRegistered(
            entityAddress,
            entityName,
            msg.sender,
            permToken,
            badgeToken
        );
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
        return badgeGnosisSafe;
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
    function setTokenReverseRecords(address perm, address badge)
        external
        override
        registeredEntity
    {
        badgeTokenEntityReverseRecord[badge] = msg.sender;
        permTokenEntityReverseRecord[perm] = msg.sender;
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
}
