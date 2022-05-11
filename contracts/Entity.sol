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
    // Enums
    enum PermLevel {
        GENESIS,
        SUPER_ADMIN,
        ADMIN
    }

    // State mgmt
    address public genesisUser;
    mapping(address => PermLevel) public permissionTokenHolders;
    address public badgeRegistry;
    address public badgeToken;
    Counters.Counter public demeritPoints;
    address public permissionToken;

    // Events
    event PermissionContractSet(address tokenAddress);

    constructor(string memory _entityName, address _badgeRegistry) payable {
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
            .createPermissionToken(_entityName, "");

        assignGenesisTokenHolder(msg.sender);
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
        string memory _tokenURI
    ) private {
        require(permissionToken != address(0), "Permission contract not set");
        if (_permLevel == PermLevel.GENESIS) {
            genesisUser = _holder;
        } else {
            IPermissionToken(permissionToken).mintAsEntity(_holder, _tokenURI);
            permissionTokenHolders[_holder] = _permLevel;
        }
    }

    function assignGenesisTokenHolder(address _holder) private {
        require(msg.sender == badgeRegistry, "Only registry can call this");
        assignPermissionTokenHolder(_holder, PermLevel.GENESIS, "");
    }

    function incrementDemeritPoints() external payable {
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

    function setPermissionContract(address _contract) external genAdminOnly {
        require(
            IPermissionToken(_contract).getEntityAddress() == address(this),
            "PermToken not set for this entity"
        );
        permissionToken = _contract;
        emit PermissionContractSet(_contract);
    }
}
