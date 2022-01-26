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
    address public badgeContract;
    address public permissionContract;
    address public upgradedContract;

    Counters.Counter public demeritPoints;

    event EntityDeployed(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );

    constructor(
        string memory _entityName,
        address _badgeContract,
        address _permissionContract,
        string memory genesisTokenURI
    ) {
        console.log("Deployed new entity:", _entityName);
        entityName = _entityName;
        badgeContract = _badgeContract;
        permissionContract = _permissionContract;

        assignPermissionTokenHolder(
            msg.sender,
            PermissionTokenType.GENESIS,
            genesisTokenURI
        );

        emit EntityDeployed(address(this), _entityName, msg.sender);
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
        require(
            _type == PermissionTokenType.ADMIN ||
                _type == PermissionTokenType.SUPER_ADMIN ||
                _type == PermissionTokenType.GENESIS,
            "Invalid permission token type"
        );
        // permissionTokenContract.createToken(_holder, _tokenURI);
        uint256 tokenId = PermissionToken(permissionContract).mintToken(
            _holder,
            _tokenURI
        );
        permissionTokenHolders[_holder] = PermissionData(_type, tokenId);
    }

    function incrementDemeritPoints() external payable {
        require(
            msg.sender == address(badgeContract),
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
}
