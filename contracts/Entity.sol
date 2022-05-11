//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BadgeToken.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IPermissionToken.sol";

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
    BadgeToken public badgeTokenContract;
    Counters.Counter public demeritPoints;
    address public permissionContract;

    // Events
    event PermissionContractSet(address tokenAddress);

    constructor(string memory _entityName, address _badgeRegistry) {
        console.log("Deployed new entity:", _entityName);
        assignGenesisTokenHolder(msg.sender);
        badgeRegistry = _badgeRegistry;
        badgeTokenContract = new BadgeToken(address(this), _entityName);
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
        require(
            permissionContract != address(0),
            "Permission contract not set"
        );
        if (_permLevel == PermLevel.GENESIS) {
            genesisUser = _holder;
        } else {
            IPermissionToken(permissionContract).mintAsEntity(
                _holder,
                _tokenURI
            );
            permissionTokenHolders[_holder] = _permLevel;
        }
    }

    function assignGenesisTokenHolder(address _holder) private {
        require(msg.sender == badgeRegistry, "Only registry can call this");
        assignPermissionTokenHolder(_holder, PermLevel.GENESIS, "");
    }

    function incrementDemeritPoints() external payable {
        require(
            msg.sender == address(badgeTokenContract),
            "Only badge token can increment demerit points"
        );
        demeritPoints.increment();
    }

    function getDemeritPoints() public view returns (uint256) {
        return demeritPoints.current();
    }

    function mintBadge(address _to, string calldata _tokenURI)
        external
        adminsOnly
    {
        badgeTokenContract.mintBadge(_to, _tokenURI);
    }

    function setPermissionContract(address _contract) external genAdminOnly {
        require(
            IPermissionToken(_contract).getEntityAddress() == address(this),
            "PermToken not set for this entity"
        );
        permissionContract = _contract;
        emit PermissionContractSet(_contract);
    }
}
