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
    address public permissionContract;
    uint256 public levelMultiplierX1000 = 2500;
    address public owner;

    address public entityFactory;
    address public badgeTokenFactory;
    address public permissionTokenFactory;
    address public badgeXPToken;
    address public badgeGnosisSafe = address(0);
    address public badgePriceCalculator;
    address public recoveryOracle;
    address public userReverseRecordOracle;

    mapping(address => bool) public entities;
    mapping(address => address) public badgeTokenEntityReverseRecord;
    mapping(address => address) public permTokenEntityReverseRecord;

    constructor() {
        owner = msg.sender;
    }

    function registerEntity(
        string calldata entityName,
        string calldata genesisTokenURI
    ) external override {
        // 1. Deploy entity
        IEntity entity = IEntityFactory(entityFactory).createEntity(
            entityName,
            recoveryOracle,
            userReverseRecordOracle,
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

    /** Getter methods */
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

    /**
    Setter functions that will be called upon deployment of the Badge registry.
     */
    function setEntityFactory(address _entityFactory) external ownerOnly {
        entityFactory = _entityFactory;
        emit EntityFactorySet(_entityFactory);
    }

    function setBadgeTokenFactory(address _badgeTokenFactory)
        external
        ownerOnly
    {
        badgeTokenFactory = _badgeTokenFactory;
        emit BadgeTokenFactorySet(_badgeTokenFactory);
    }

    function setPermissionTokenFactory(address _permissionTokenFactory)
        external
        ownerOnly
    {
        permissionTokenFactory = _permissionTokenFactory;
        emit PermissionTokenFactorySet(_permissionTokenFactory);
    }

    function setBadgeXPToken(address _badgeXPToken) external ownerOnly {
        badgeXPToken = _badgeXPToken;
        emit BadgeXPTokenSet(_badgeXPToken);
    }

    function setBadgePriceCalculator(address _badgePriceCalculator)
        external
        ownerOnly
    {
        badgePriceCalculator = _badgePriceCalculator;
        emit BadgePriceCalculatorSet(badgePriceCalculator);
    }

    function setRecoveryOracle(address _recoveryOracle) external ownerOnly {
        // Recovery oracle can only ever be set once
        if (recoveryOracle != address(0)) {
            recoveryOracle = _recoveryOracle;
            emit RecoveryOracleSet(recoveryOracle);
        }
    }

    function setUserReverseRecordOracle(address _userReverseRecordOracle)
        external
        ownerOnly
    {
        userReverseRecordOracle = _userReverseRecordOracle;
        emit UserReverseRecordOracleSet(userReverseRecordOracle);
    }
}
