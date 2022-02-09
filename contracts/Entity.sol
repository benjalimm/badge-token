//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";

contract Entity {
    using Counters for Counters.Counter;

    enum PermissionTokenType {
        ADMIN,
        SUPER_ADMIN,
        GENESIS
    }

    struct PermissionData {
        PermissionTokenType permType;
        uint256 permissionId;
    }

    string public entityName;
    mapping(address => PermissionData) public permissionTokenHolders;

    address public badgeRegistry;
    address public permissionContract;
    address public upgradedContract;

    BadgeToken public badgeTokenContract;

    Counters.Counter public demeritPoints;

    constructor(
        string memory _entityName,
        address _badgeRegistry,
        address _permissionContract
    ) {
        console.log("Deployed new entity:", _entityName);
        entityName = _entityName;
        badgeRegistry = _badgeRegistry;
        permissionContract = _permissionContract;
        badgeTokenContract = new BadgeToken(address(this), _entityName);
    }

    modifier genAdminOnly() {
        require(
            permissionTokenHolders[msg.sender].permType ==
                PermissionTokenType.GENESIS,
            "Gen privileges required"
        );
        _;
    }

    modifier genOrSuperAdminOnly() {
        require(
            permissionTokenHolders[msg.sender].permType ==
                PermissionTokenType.SUPER_ADMIN ||
                permissionTokenHolders[msg.sender].permType ==
                PermissionTokenType.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    modifier adminsOnly() {
        require(
            permissionTokenHolders[msg.sender].permType ==
                PermissionTokenType.ADMIN ||
                permissionTokenHolders[msg.sender].permType ==
                PermissionTokenType.SUPER_ADMIN ||
                permissionTokenHolders[msg.sender].permType ==
                PermissionTokenType.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    function assignPermissionTokenHolder(
        address _holder,
        PermissionTokenType _type,
        string memory _tokenURI
    ) private {
        uint256 tokenId = PermissionToken(permissionContract).mintToken(
            _holder,
            _tokenURI
        );
        permissionTokenHolders[_holder] = PermissionData(_type, tokenId);
    }

    function assignGenesisTokenHolder(address _holder, string memory _tokenURI)
        external
    {
        require(msg.sender == badgeRegistry, "Only registry can call this");
        assignPermissionTokenHolder(
            _holder,
            PermissionTokenType.GENESIS,
            _tokenURI
        );
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

    function setUpgradedEntityContract(address _contract)
        external
        genAdminOnly
    {
        upgradedContract = _contract;
    }

    function mintBadge(address _to, string memory _tokenURI)
        external
        adminsOnly
    {
        badgeTokenContract.mintBadge(_to, _tokenURI);
    }
}
