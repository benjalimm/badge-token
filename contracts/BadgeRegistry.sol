//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";

contract BadgeRegistry {
    mapping(address => bool) public entities;
    address public badgeContract;
    address public permissionContract;

    constructor() {
        badgeContract = address(new BadgeToken(address(this)));
        permissionContract = address(new PermissionToken(address(this)));
    }

    event EntityDeployed(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );

    function deployEntity(string calldata name, string calldata genesisTokenURI)
        external
        payable
    {
        Entity e = new Entity(
            name,
            address(this),
            badgeContract,
            permissionContract
        );
        entities[address(e)] = true;

        e.assignGenesisTokenHolder(msg.sender, genesisTokenURI);

        emit EntityDeployed(address(e), name, msg.sender);
    }

    function isRegistered(address addr) external view returns (bool) {
        return entities[addr];
    }
}
