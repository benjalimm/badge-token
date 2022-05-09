//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BadgeToken.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IPermissionToken.sol";

contract Entity is BaseRelayRecipient {
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

    string public override versionRecipient = "2.2.0";

    string public entityName;
    mapping(address => PermissionData) public permissionTokenHolders;
    address public badgeRegistry;
    address public upgradedContract;
    BadgeToken public badgeTokenContract;
    Counters.Counter public demeritPoints;
    address public permissionContract;

    event PermissionContractSet(address tokenAddress);

    constructor(
        string memory _entityName,
        address _badgeRegistry,
        address _forwarder
    ) {
        console.log("Deployed new entity:", _entityName);
        _setTrustedForwarder(_forwarder);
        entityName = _entityName;
        badgeRegistry = _badgeRegistry;
        badgeTokenContract = new BadgeToken(address(this), _entityName);
    }

    modifier genAdminOnly() {
        require(
            permissionTokenHolders[_msgSender()].permType ==
                PermissionTokenType.GENESIS,
            "Gen privileges required"
        );
        _;
    }

    modifier genOrSuperAdminOnly() {
        require(
            permissionTokenHolders[_msgSender()].permType ==
                PermissionTokenType.SUPER_ADMIN ||
                permissionTokenHolders[_msgSender()].permType ==
                PermissionTokenType.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    modifier adminsOnly() {
        require(
            permissionTokenHolders[_msgSender()].permType ==
                PermissionTokenType.ADMIN ||
                permissionTokenHolders[_msgSender()].permType ==
                PermissionTokenType.SUPER_ADMIN ||
                permissionTokenHolders[_msgSender()].permType ==
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
        require(
            permissionContract != address(0),
            "Permission contract not set"
        );
        uint256 tokenId = IPermissionToken(permissionContract).mintAsEntity(
            _holder,
            _tokenURI
        );
        permissionTokenHolders[_holder] = PermissionData(_type, tokenId);
    }

    function assignGenesisTokenHolder(address _holder, string memory _tokenURI)
        external
    {
        require(_msgSender() == badgeRegistry, "Only registry can call this");
        assignPermissionTokenHolder(
            _holder,
            PermissionTokenType.GENESIS,
            _tokenURI
        );
    }

    function incrementDemeritPoints() external payable {
        require(
            _msgSender() == address(badgeTokenContract),
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

    function setPermissionContract(address _contract) external genAdminOnly {
        require(
            IPermissionToken(_contract).getEntityAddress() == address(this),
            "PermToken not set for this entity"
        );
        permissionContract = _contract;
        emit PermissionContractSet(_contract);
    }
}
