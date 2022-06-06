//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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
    using Counters for Counters.Counter;

    string public entityName;
    address public genesisTokenHolder;

    // ** Pertinent addresses ** \\
    address public badgeRegistry;
    address public badgeToken;
    Counters.Counter public demeritPoints;
    address public permissionToken;

    constructor(
        string memory _entityName,
        address _badgeRegistry,
        address _recoveryOracle,
        address _genesisTokenHolder,
        string memory _genesisTokenURI
    ) {
        console.log("Deployed new entity:", _entityName);
        badgeRegistry = _badgeRegistry;
        entityName = _entityName;
        genesisTokenHolder = _genesisTokenHolder;

        // 1. Create Badge token contract
        address badgeTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
            .getBadgeTokenFactory();
        badgeToken = IBadgeTokenFactory(badgeTokenFactoryAddress)
            .createBadgeToken(_entityName, _recoveryOracle);

        // 2. Create Permission token contract
        address permissionTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
            .getPermissionTokenFactory();
        permissionToken = IPermissionTokenFactory(permissionTokenFactoryAddress)
            .createPermissionToken(_entityName);

        // 3. Mint genesis token
        IPermissionToken(permissionToken).mintAsEntity(
            msg.sender,
            PermLevel.GENESIS,
            _genesisTokenURI
        );
    }

    // ** Modifiers ** \\
    modifier gen() {
        if (msg.sender != genesisTokenHolder)
            revert Unauthorized("Genesis holder only");
        _;
    }

    modifier genOrSuper() {
        if (
            (IPermissionToken(permissionToken).getPermStatusForUser(
                msg.sender
            ) != PermLevel.SUPER_ADMIN) || (genesisTokenHolder != msg.sender)
        ) revert Unauthorized("Super users only");
        _;
    }

    modifier admins() {
        PermLevel level = IPermissionToken(permissionToken)
            .getPermStatusForUser(msg.sender);
        if (
            level != PermLevel.ADMIN ||
            level != PermLevel.SUPER_ADMIN ||
            msg.sender != genesisTokenHolder
        ) revert Unauthorized("Admins only");
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

    function getDemeritPoints() public view returns (uint256) {
        return demeritPoints.current();
    }

    function getBadgeXPToken() private view returns (address) {
        return IBadgeRegistry(badgeRegistry).getBadgeXPToken();
    }

    // ** Setter functions ** \\

    function setNewEntity(address _entity, address _registry)
        external
        genOrSuper
    {
        // 1. Make sure entity comes from a certified registry
        if (!IBadgeRegistry(badgeRegistry).isRegistryCertified(_registry))
            revert Unauthorized("Registry is not certified");
        if (!IBadgeRegistry(_registry).isRegistered(_entity))
            revert Unauthorized("Entity is not registered to registry");

        // 2. Set new entity
        IBadgeToken(badgeToken).setNewEntity(_entity);
        IPermissionToken(permissionToken).setNewEntity(_entity);
    }
}
