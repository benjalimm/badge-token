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
    // State mgmt

    address public badgeRegistry;
    address public badgeToken;
    Counters.Counter public demeritPoints;
    address public permissionToken;

    constructor(
        string memory _entityName,
        address _badgeRegistry,
        address _genesisTokenHolder
    ) {
        console.log("Deployed new entity:", _entityName);
        badgeRegistry = _badgeRegistry;
        entityName = _entityName;
        genesisTokenHolder = _genesisTokenHolder;

        // Create Badge token contract
        address badgeTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
            .getBadgeTokenFactory();
        badgeToken = IBadgeTokenFactory(badgeTokenFactoryAddress)
            .createBadgeToken(_entityName);
    }

    modifier genAdminOnly() {
        require(
            msg.sender == genesisTokenHolder,
            "Only genesis token holder can call this"
        );
        _;
    }

    modifier genOrSuperAdminOnly() {
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

    modifier adminsOnly() {
        require(
            IPermissionToken(permissionToken).getPermStatusForUser(
                msg.sender
            ) ==
                PermLevel.ADMIN ||
                IPermissionToken(permissionToken).getPermStatusForUser(
                    msg.sender
                ) ==
                PermLevel.SUPER_ADMIN ||
                genesisTokenHolder == msg.sender,
            "Sender has no admin privilege"
        );
        _;
    }

    /**
     * @dev Creates a new permission token for the entity, which allows more than one user to issue Badges on behalf of the entity.
     * @param genesisTokenURI The URI of the initial genesis token.
     */
    function deployPermToken(string calldata genesisTokenURI)
        external
        genAdminOnly
    {
        // 1. Create Permission token contract
        address permissionTokenFactoryAddress = IBadgeRegistry(badgeRegistry)
            .getPermissionTokenFactory();
        permissionToken = IPermissionTokenFactory(permissionTokenFactoryAddress)
            .createPermissionToken(entityName);

        // 2. Mint genesis token
        IPermissionToken(permissionToken).mintAsEntity(
            msg.sender,
            PermLevel.GENESIS,
            genesisTokenURI
        );
    }

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

    function incrementDemeritPoints() external override {
        require(
            msg.sender == address(badgeToken),
            "Only badge token can increment demerit points"
        );
        demeritPoints.increment();
    }

    function getDemeritPoints() public view returns (uint256) {
        return demeritPoints.current();
    }

    function getBadgeXPToken() private view returns (address) {
        return IBadgeRegistry(badgeRegistry).getBadgeXPToken();
    }

    function mintBadge(
        address to,
        uint256 level,
        string calldata _tokenURI
    ) external payable override adminsOnly {
        require(level >= 0, "Level cannot be less than 0");
        uint256 badgePrice = IBadgeRegistry(badgeRegistry).getBadgePrice(level);
        require(msg.value >= badgePrice, "Not enough ETH");

        address safe = IBadgeRegistry(badgeRegistry).getSafe();
        (bool success, ) = safe.call{value: badgePrice}("");
        require(success, "Call to safe failed");
        IBadgeToken(badgeToken).mintBadge(to, level, _tokenURI);
        IBadgeXP(getBadgeXPToken()).mint(level, to);
    }

    function getBadgeRegistry() external view override returns (address) {
        return badgeRegistry;
    }

    function getPermissionToken() external view override returns (address) {
        return permissionToken;
    }

    function getBadgeToken() external view override returns (address) {
        return badgeToken;
    }
}
