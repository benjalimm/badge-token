//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BadgeToken.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IBadgeTokenFactory.sol";
import "../interfaces/IPermissionToken.sol";
import "../interfaces/IPermissionTokenFactory.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeXP.sol";
import "../interfaces/IEntity.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Entity is IEntity {
    string public constant VERSION = "1.0";

    // ** Events ** \\
    event GenesisTokenReassigned(address from, address to);
    event EntityMigrated(address newEntity);
    event TokensMigrated(address newBadgeToken, address newPermToken);
    event RecipientReset(address from, address to, uint256 tokenId, uint256 xp);

    // ** Constants ** \\
    uint256 public immutable BASE_MINIMUM_STAKE;

    // ** Permissions ** \\
    enum PermLevel {
        None,
        Admin,
        SuperAdmin,
        Genesis
    }

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
        BASE_MINIMUM_STAKE = IBadgeRegistry(_badgeRegistry)
            .getBaseMinimumStake();

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
            mintPermissionToken(
                _genesisTokenHolder,
                PermLevel.Genesis,
                _genesisTokenURI
            );
        }
    }

    // ** Convenience functions ** \\
    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    // ** Modifiers ** \\

    /// Genesis user only ///
    modifier gen() {
        require(
            msg.sender == genesisTokenHolder,
            "Only genesis token holder can call this"
        );
        _;
    }

    /// Super admins and higher only ///
    modifier genOrSuper() {
        require(
            IPermissionToken(permissionToken).getPermStatusForAdmin(
                msg.sender
            ) > 1,
            "Sender has no super user privilege"
        );
        _;
    }

    /// Admins only ///
    modifier admins() {
        require(
            IPermissionToken(permissionToken).getPermStatusForAdmin(
                msg.sender
            ) > 0,
            "Sender has no admin privilege"
        );
        _;
    }

    // Minimum ETH stake required in Badge token
    modifier minStakeReq() {
        require(
            // Allow for 2% slippage
            badgeToken.balance >= ((98 * getMinStake()) / 100),
            "Not enough stake"
        );
        _;
    }

    modifier blockSelf(address to) {
        require(msg.sender != to, "Cannot send to self");
        _;
    }

    // ** BADGE METHODS ** \\

    function mintBadge(
        address to,
        uint8 level,
        string calldata _tokenURI
    ) external payable admins minStakeReq blockSelf(to) {
        require(level >= 0, "Level cannot be less than 0");

        // 1. Get Badge mint price based on level
        uint256 badgePrice = IBadgeRegistry(badgeRegistry).getBadgePrice(level);
        require(msg.value >= badgePrice, "Not enough ETH to mint badge");

        // 2. Send eth to contract
        address safe = IBadgeRegistry(badgeRegistry).getSafe();
        (bool success, ) = safe.call{value: badgePrice}("");
        require(success, "Call to safe failed");

        // 3. Mint BadgeXP points
        uint256 xp = IBadgeXP(getBadgeXPToken()).mint(level, to, badgeRegistry);

        // 4. Mint badge
        IBadgeToken(badgeToken).mintBadge(to, level, xp, _tokenURI);
    }

    /// Burn Badge - For admins ///
    function burnBadge(uint256 id) external admins minStakeReq {
        // 1. Get xp points
        uint256 xp = IBadgeToken(badgeToken).getXPForBadge(id);

        // 2. Get owner
        address owner = IERC721(badgeToken).ownerOf(id);

        // 3. Burn XP
        (bool xpSuccess, ) = getBadgeXPToken().call(
            abi.encodeWithSelector(
                IBadgeXP.burn.selector,
                xp,
                owner,
                badgeRegistry
            )
        );

        require(xpSuccess, "Call to Badge XP failed");

        // 4. Burn Badge
        (bool tokenSuccess, ) = badgeToken.call(
            abi.encodeWithSelector(IBadgeToken.burnAsEntity.selector, id)
        );

        require(tokenSuccess, "Call to Badge token failed");
    }

    function resetBadgeURI(uint256 id, string memory tokenURI)
        external
        admins
        minStakeReq
    {
        IBadgeToken(badgeToken).resetBadgeURI(id, tokenURI);
    }

    function resetBadgeRecipient(uint256 id, address to)
        external
        admins
        minStakeReq
        blockSelf(to)
    {
        // 1. Get xp points
        uint256 xp = IBadgeToken(badgeToken).getXPForBadge(id);
        address previousRecipient = IERC721(badgeToken).ownerOf(id);
        // 2. Reset Badge recipient
        IBadgeToken(badgeToken).resetBadgeRecipient(id, to);
        /// Step 1 will ensure that the change can only be made within the time limit. Hence, if this is made outside the time limit (15 days), this first method will fail.

        // 2. Reset BadgeXP points
        IBadgeXP(getBadgeXPToken()).resetXP(
            xp,
            previousRecipient,
            to,
            badgeRegistry
        );

        emit RecipientReset(previousRecipient, to, id, xp);
    }

    /// BadgeToken can call this to burn XP points ///
    /// For recipients to burn Badges, they need to do at the BadgeToken level .As only reg entities can call BadgeXP contract, we need to expose a function for the badgetoken to call
    function burnXPAsBadgeToken(uint256 xp, address owner) external override {
        if (msg.sender != badgeToken)
            revert Unauthorized("Only BadgeToken can call  this");

        IBadgeXP(getBadgeXPToken()).burn(xp, owner, badgeRegistry);
    }

    function setTokenSite(string memory site) external admins minStakeReq {
        IBadgeToken(badgeToken).setTokenSite(site);
    }

    // ** PERMISSION FUNCTIONS ** \\

    /// Mint Permission - Convert level enum to uint256 ///
    function mintPermissionToken(
        address to,
        PermLevel level,
        string memory _tokenURI
    ) private {
        IPermissionToken(permissionToken).mintAsEntity(
            to,
            uint256(level),
            _tokenURI
        );
    }

    function assignPermissionToken(
        address assignee,
        PermLevel level,
        string calldata tokenURI
    ) external {
        // 1. Get level of assigner
        uint256 assignerLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(msg.sender);

        // 2. Check if assigner has permission to assign
        require(
            assignerLevel > uint256(level),
            "Can't assign permission with higher or equal level"
        );

        // 3. Assign
        mintPermissionToken(assignee, level, tokenURI);
    }

    function revokePermissionToken(address revokee) external genOrSuper {
        // 1. Get level of revoker
        uint256 revokerLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(msg.sender);

        // 2. Get level of revokee
        uint256 revokeeLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(revokee);
        require(
            uint256(revokerLevel) > uint256(revokeeLevel),
            "Assigner has no permission"
        );

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
        uint256 assigneeLevel = IPermissionToken(permissionToken)
            .getPermStatusForAdmin(assignee);
        if (assigneeLevel != 2)
            revert Unauthorized(
                "New genesis holder has to be at least a super admin"
            );

        // 2. Burn current user existing genesis token
        IPermissionToken(permissionToken).revokePermission(msg.sender);

        // 3. Burn new assignee's existing permission
        IPermissionToken(permissionToken).revokePermission(assignee);

        // 4. Assign new genesis token holder
        genesisTokenHolder = assignee;
        mintPermissionToken(assignee, PermLevel.Genesis, tokenURI);

        // 5. Assign new super admin
        if (switchToSuper) {
            mintPermissionToken(
                msg.sender,
                PermLevel.SuperAdmin,
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

    function getBadgeXPToken() public view override returns (address) {
        return IBadgeRegistry(badgeRegistry).getBadgeXPToken();
    }

    function getMinStake() public view returns (uint256) {
        return calculateMinStake(IBadgeToken(badgeToken).getDemeritPoints());
    }

    function getGenUser() external view override returns (address) {
        return genesisTokenHolder;
    }

    function calculateMinStake(uint256 demeritPoints)
        public
        view
        override
        returns (uint256)
    {
        /// Algo for calculating min stake
        /// As demerit points go up (from Badge being burned with prejudice).
        /// The stake required for goes up.

        return
            (BASE_MINIMUM_STAKE * (1000 + ((demeritPoints**2) * 100))) / 1000;
    }

    // ** MIGRATIONS FUNCTIONS ** \\

    // Organizations can migrate to new entities, allowing for them to upgrade to entities that possess new functionalities. This is how the migration is executed:

    /// Step 1 - Deploy new entity (without deploying new badge / permission tokens)

    /// Step 2 - Migrate to entity - Set new entity address in badge + perm tokens  (Method below)

    /// Step 3 - Migrate to tokens - Set existing badge + permission tokens in new entity

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

        emit TokensMigrated(badge, permission);
    }
}
