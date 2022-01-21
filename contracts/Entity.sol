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
    BadgeToken public badgeTokenContract;
    PermissionToken public permissionTokenContract;
    Counters.Counter public demeritPoints;

    event EntityDeployed(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );

    constructor(string memory _entityName, string memory _genesisTokenURI) {
        console.log("Deployed new entity:", _entityName);
        entityName = _entityName;

        // Init Permission token contract
        // permissionTokenContract = new PermissionToken(
        //     address(this),
        //     _entityName
        // );

        // Initialize the Badge token contract
        badgeTokenContract = new BadgeToken(address(this), _entityName);

        // Assign Genesis Badge token
        assignPermissionTokenHolder(
            msg.sender,
            PermissionTokenType.GENESIS,
            _genesisTokenURI
        );

        emit EntityDeployed(address(this), _entityName, msg.sender);
    }

    modifier genAdminOnly() {
        require(
            permissionTokenHolders[msg.sender] == PermissionTokenType.GENESIS,
            "Sender has no genesis user privilege"
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
        PermissionTokenType _type,
        string memory _tokenURI
    ) private {
        require(
            _type == PermissionTokenType.ADMIN ||
                _type == PermissionTokenType.SUPER_ADMIN ||
                _type == PermissionTokenType.GENESIS,
            "Invalid permission token type"
        );

        permissionTokenHolders[_holder] = _type;

        permissionTokenContract.createToken(_holder, _tokenURI);
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
}
