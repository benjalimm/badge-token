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

    string public entityName;
    mapping(address => PermissionTokenType) public permissionTokenHolders;
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
        address _permissionContract
    ) {
        console.log("Deployed new entity:", _entityName);
        entityName = _entityName;
        badgeContract = _badgeContract;
        permissionContract = _permissionContract;

        assignPermissionTokenHolder(msg.sender, PermissionTokenType.GENESIS);

        emit EntityDeployed(address(this), _entityName, msg.sender);
    }

    modifier genAdminOnly() {
        require(
            permissionTokenHolders[msg.sender] == PermissionTokenType.GENESIS,
            "Gen privileges required"
        );
        _;
    }

    modifier genOrSuperAdminOnly() {
        require(
            permissionTokenHolders[msg.sender] ==
                PermissionTokenType.SUPER_ADMIN ||
                permissionTokenHolders[msg.sender] ==
                PermissionTokenType.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    modifier adminsOnly() {
        require(
            permissionTokenHolders[msg.sender] == PermissionTokenType.ADMIN ||
                permissionTokenHolders[msg.sender] ==
                PermissionTokenType.SUPER_ADMIN ||
                permissionTokenHolders[msg.sender] ==
                PermissionTokenType.GENESIS,
            "Sender has no super user privilege"
        );
        _;
    }

    function assignPermissionTokenHolder(
        address _holder,
        PermissionTokenType _type
    ) private {
        require(
            _type == PermissionTokenType.ADMIN ||
                _type == PermissionTokenType.SUPER_ADMIN ||
                _type == PermissionTokenType.GENESIS,
            "Invalid permission token type"
        );

        permissionTokenHolders[_holder] = _type;

        // permissionTokenContract.createToken(_holder, _tokenURI);
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
