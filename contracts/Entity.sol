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
    // ** Events ** \\
    event GenesisTokenReassigned(address from, address to);
    event EntityMigrated(address newEntity);
    event TokensMigrated(address newBadgeToken, address newPermToken);

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

        // 1. Set pertinent info for entity
        badgeRegistry = _badgeRegistry;
        entityName = _entityName;
        genesisTokenHolder = _genesisTokenHolder;

        if (deployTokens) {
            // 2. Create Badge token contract
            address badgeTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
                .getBadgeTokenFactory();
            badgeToken = IBadgeTokenFactory(badgeTokenFactoryAddress)
                .createBadgeToken(_entityName, _recoveryOracle);

            // 3. Create Permission token contract
            address permissionTokenFactoryAddress = IBadgeRegistry(
                _badgeRegistry
            ).getPermissionTokenFactory();
            permissionToken = IPermissionTokenFactory(
                permissionTokenFactoryAddress
            ).createPermissionToken(_entityName);

            // 4. Mint genesis token
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
            IPermissionToken(permissionToken).getPermStatusForAdmin(
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
            .getPermStatusForAdmin(msg.sender);
        require(
            level == PermLevel.ADMIN ||
                level == PermLevel.SUPER_ADMIN ||
                genesisTokenHolder == msg.sender,
            "Sender has no admin privilege"
        );
        _;
    }

    // ** Entity functions ** \\

    function mintBadge(
        address to,
        uint256 level,
        string calldata _tokenURI
    ) external payable override admins {
        require(level >= 0, "Level cannot be less than 0");

        // 1. Get Badge burn price
        uint256 badgePrice = IBadgeRegistry(badgeRegistry).getBadgePrice(level);
        require(msg.value >= badgePrice, "Not enough ETH");

        // 2. Send eth to contract
        address safe = IBadgeRegistry(badgeRegistry).getSafe();
        (bool success, ) = safe.call{value: badgePrice}("");
        require(success, "Call to safe failed");

        // 3. Mint badge
        IBadgeToken(badgeToken).mintBadge(to, level, _tokenURI);

        // 4. Mint BadgeXP points
        IBadgeXP(getBadgeXPToken()).mint(level, to, badgeRegistry);
    }

    // ** Permission functions ** \\
    function assignPermissionToken(
        address assignee,
        PermLevel level,
        string calldata tokenURI
    ) external override {
        // 1. Get level of assigner
        PermLevel assignerLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(msg.sender);

        // 2. Check if assigner has permission to assign
        require(assignerLevel > level, "Assigner has no permission");

        // 3. Assign
        IPermissionToken(permissionToken).mintAsEntity(
            assignee,
            level,
            tokenURI
        );
    }

    function revokePermissionToken(address revokee) external genOrSuper {
        // 1. Get level of revoker
        PermLevel revokerLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(msg.sender);

        // 2. Get level of revokee
        PermLevel revokeeLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(revokee);
        require(revokerLevel > revokeeLevel, "Assigner has no permission");

        // 3. Revoke permissions
        IPermissionToken(permissionToken).revokePermission(revokee);
    }

    function surrenderPermissionToken() external admins {
        if (msg.sender == genesisTokenHolder)
            revert Failure("Cannot surrender genesis token");
        IPermissionToken(permissionToken).revokePermission(msg.sender);
    }

    function reassignGenesisToken(
        address assignee,
        string memory tokenURI,
        bool switchToSuper,
        string memory superTokenURI
    ) external gen {
        // 1. Make sure assignee is an existing super admin
        PermLevel assigneeLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(assignee);
        if (assigneeLevel != PermLevel.SUPER_ADMIN)
            revert Unauthorized(
                "New genesis holder has to be at least a super admin"
            );

        // 2. Burn current user existing genesis token
        IPermissionToken(permissionToken).revokePermission(msg.sender);

        // 3. Burn new assignee's existing permission
        IPermissionToken(permissionToken).revokePermission(assignee);

        // 4. Assign new genesis token holder
        genesisTokenHolder = assignee;
        IPermissionToken(permissionToken).mintAsEntity(
            assignee,
            PermLevel.GENESIS,
            tokenURI
        );

        // 5. Assign new super admin
        if (switchToSuper) {
            IPermissionToken(permissionToken).mintAsEntity(
                msg.sender,
                PermLevel.SUPER_ADMIN,
                superTokenURI
            );
        }

        emit GenesisTokenReassigned(msg.sender, assignee);
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
