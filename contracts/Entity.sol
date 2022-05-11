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

contract Entity {
    using Counters for Counters.Counter;

    enum PermLevel {
        ADMIN,
        SUPER_ADMIN,
        GENESIS
    }

    // State mgmt
    mapping(address => PermLevel) public permissionTokenHolders;
    address public badgeRegistry;
    address public badgeToken;
    Counters.Counter public demeritPoints;
    address public permissionToken;

    // Events
    event PermissionTokenAssigned(
        address entityAddress,
        address assigner,
        PermLevel assignerLevel,
        address assignee,
        PermLevel assigneeLevel
    );

    constructor(string memory _entityName, address _badgeRegistry) {
        console.log("Deployed new entity:", _entityName);
        badgeRegistry = _badgeRegistry;

        // Create Badge token contract
        address badgeTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
            .getBadgeTokenFactory();
        badgeToken = IBadgeTokenFactory(badgeTokenFactoryAddress)
            .createBadgeToken(_entityName);

        // Create Permission token contract
        address permissionTokenFactoryAddress = IBadgeRegistry(_badgeRegistry)
            .getPermissionTokenFactory();
        permissionToken = IPermissionTokenFactory(permissionTokenFactoryAddress)
            .createPermissionToken(_entityName);
    }

    modifier genAdminOnly() {
        require(
            permissionTokenHolders[msg.sender] == PermLevel.GENESIS,
            "Gen privileges required"
        );
        _;
    }

    modifier genOrSuperAdminOnly() {
        require(
            permissionTokenHolders[msg.sender] == PermLevel.SUPER_ADMIN ||
                permissionTokenHolders[msg.sender] == PermLevel.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    modifier adminsOnly() {
        require(
            permissionTokenHolders[msg.sender] == PermLevel.ADMIN ||
                permissionTokenHolders[msg.sender] == PermLevel.SUPER_ADMIN ||
                permissionTokenHolders[msg.sender] == PermLevel.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    function assignPermissionTokenHolder(
        address _holder,
        PermLevel _permLevel,
        string calldata _tokenURI
    ) private {
        permissionTokenHolders[_holder] = _permLevel;
        IPermissionToken(permissionToken).mintAsEntity(_holder, _tokenURI);
    }

    function assignPermissionToken(
        address assignee,
        PermLevel level,
        string calldata tokenURI
    ) external {
        // 1. Get level of assigner
        PermLevel assignerLevel = permissionTokenHolders[msg.sender];
        require(assignerLevel > level, "Assigner has no permission");
        assignPermissionTokenHolder(assignee, level, tokenURI);
        emit PermissionTokenAssigned(
            address(this),
            msg.sender,
            assignerLevel,
            assignee,
            level
        );
    }

    function incrementDemeritPoints() external {
        require(
            msg.sender == address(badgeToken),
            "Only badge token can increment demerit points"
        );
        demeritPoints.increment();
    }

    function getDemeritPoints() public view returns (uint256) {
        return demeritPoints.current();
    }

    function mintBadge(address _to, string calldata _tokenURI)
        external
        payable
        adminsOnly
    {
        IBadgeToken(badgeToken).mintBadge(_to, _tokenURI);
    }
}
