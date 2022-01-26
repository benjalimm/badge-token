//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";

contract BadgeRegistry {
    mapping(address => string) public entities;
    address public badgeContract;
    address public permissionContract;

    constructor() {
        badgeContract = address(new BadgeToken(address(this)));
        permissionContract = address(new PermissionToken(address(this)));
        console.log("Badge contract address: ");
        console.log(badgeContract);
        console.log("Permission contract address: ");
        console.log(permissionContract);
    }

    function deployEntity(string calldata name, string calldata genesisTokenURI)
        external
        payable
    {
        Entity e = new Entity(
            name,
            badgeContract,
            permissionContract,
            genesisTokenURI
        );
        entities[address(e)] = name;
    }

    function isRegistered(address addr) external pure returns (bool) {
        return (keccak256(abi.encodePacked(addr)) ==
            keccak256(abi.encodePacked("")));
    }
}
