//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BadgeToken.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IBadgeTokenFactory.sol";
import "../interfaces/IPermissionToken.sol";
import "../interfaces/IPermissionTokenFactory.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeXP.sol";
import "../interfaces/IEntity.sol";

contract Entity is IEntity {
    // ** Entity info ** \\
    string public entityName;
    address public genesisTokenHolder;

    // ** Pertinent addresses ** \\
    address public badgeRegistry;
    address public badgeToken;
    address public permissionToken;

    constructor(
        string memory _entityName,
        address _badgeRegistry,
        address _recoveryOracle,
        address _genesisTokenHolder,
        string memory _genesisTokenURI,
        bool deployTokens
    ) {
        console.log("Deployed new entity:", _entityName);
        badgeRegistry = _badgeRegistry;
        entityName = _entityName;
        genesisTokenHolder = _genesisTokenHolder;

        if (deployTokens) {
            // 1. Create Badge token contract
            address badgeTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
                .getBadgeTokenFactory();
            badgeToken = IBadgeTokenFactory(badgeTokenFactoryAddress)
                .createBadgeToken(_entityName, _recoveryOracle);

            // 2. Create Permission token contract
            address permissionTokenFactoryAddress = IBadgeRegistry(
                _badgeRegistry
            ).getPermissionTokenFactory();
            permissionToken = IPermissionTokenFactory(
                permissionTokenFactoryAddress
            ).createPermissionToken(_entityName);

            // 3. Mint genesis token
            IPermissionToken(permissionToken).mintAsEntity(
                msg.sender,
                PermLevel.GENESIS,
                _genesisTokenURI
            );
        }
    }

    // ** Modifiers ** \\

    modifier gen() {
        require(
            msg.sender == genesisTokenHolder,
            "Only genesis token holder can call this"
        );
        _;
    }

    modifier genOrSuper() {
        require(
            IPermissionToken(permissionToken).getPermStatusForUser(
                msg.sender
            ) ==
                PermLevel.SUPER_ADMIN ||
                genesisTokenHolder == msg.sender,
            "Sender has no super user privilege"
        );
        _;
    }

    modifier admins() {
        PermLevel level = IPermissionToken(permissionToken)
            .getPermStatusForUser(msg.sender);
        require(
            level == PermLevel.ADMIN ||
                level == PermLevel.SUPER_ADMIN ||
                genesisTokenHolder == msg.sender,
            "Sender has no admin privilege"
        );
        _;
    }

    // ** Entity functions ** \\
    function assignPermissionToken(
        address assignee,
        PermLevel level,
        string calldata tokenURI
    ) external override {
        // 1. Get level of assigner
        PermLevel assignerLevel = IPermissionToken(permissionToken)
            .getPermStatusForUser(msg.sender);
        require(assignerLevel > level, "Assigner has no permission");
        IPermissionToken(permissionToken).mintAsEntity(
            assignee,
            level,
            tokenURI
        );
        emit PermissionTokenAssigned(
            address(this),
            msg.sender,
            assignerLevel,
            assignee,
            level
        );
    }

    function revokePermissionToken(address assignee) external genOrSuper {
        // 1. Get level of assigner

        PermLevel revokerLevel = IPermissionToken(permissionToken)
            .getPermStatusForUser(msg.sender);
        PermLevel assigneeLevel = IPermissionToken(permissionToken)
            .getPermStatusForUser(assignee);
        require(revokerLevel > assigneeLevel, "Assigner has no permission");
    }

    function mintBadge(
        address to,
        uint256 level,
        string calldata _tokenURI
    ) external payable override admins {
        require(level >= 0, "Level cannot be less than 0");
        uint256 badgePrice = IBadgeRegistry(badgeRegistry).getBadgePrice(level);
        require(msg.value >= badgePrice, "Not enough ETH");

        address safe = IBadgeRegistry(badgeRegistry).getSafe();
        (bool success, ) = safe.call{value: badgePrice}("");
        require(success, "Call to safe failed");
        IBadgeToken(badgeToken).mintBadge(to, level, _tokenURI);
        IBadgeXP(getBadgeXPToken()).mint(level, to, badgeRegistry);
    }

    // ** Getter functions ** \\
    function getBadgeRegistry() external view override returns (address) {
        return badgeRegistry;
    }

    function getPermissionToken() external view override returns (address) {
        return permissionToken;
    }

    function getBadgeToken() external view override returns (address) {
        return badgeToken;
    }

    function getBadgeXPToken() private view returns (address) {
        return IBadgeRegistry(badgeRegistry).getBadgeXPToken();
    }

    // ** Setter functions ** \\

    function migrateToEntity(address _entity, address _registry) external gen {
        // 1. Make sure entity comes from a certified registry
        if (!IBadgeRegistry(badgeRegistry).isRegistryCertified(_registry))
            revert Unauthorized("Registry is not certified");
        if (!IBadgeRegistry(_registry).isRegistered(_entity))
            revert Unauthorized("Entity is not registered to registry");

        // 2. Set new entity
        IBadgeToken(badgeToken).setNewEntity(_entity);
        IPermissionToken(permissionToken).setNewEntity(_entity);

        emit EntityMigrated(_entity);
    }

    function migrateToTokens(address badge, address permission) external gen {
        // 1. Make sure entity has been set in badge and perm tokens
        if (IBadgeToken(badge).getEntity() != address(this))
            revert Unauthorized("Badge token is not owned by entity");

        if (IPermissionToken(permission).getEntity() != address(this))
            revert Unauthorized("Permission token is not owned by entity");

        // 2. Set tokens;
        badgeToken = badge;
        permissionToken = permission;

        // 3. Set reverse registry in BadgeRegistry
        IBadgeRegistry(badgeRegistry).setTokenReverseRecords(badge, permission);

        emit TokensMigrated(badge, permission);
    }
}
