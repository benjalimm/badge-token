//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";

contract BadgeRegistry {
    mapping(address => string) public entities;
    address public badgeContract;
    address public permissionContract;

    constructor(address _badgeContract, address _permissionContract) {
        console.log("Successfully deployed");
        badgeContract = _badgeContract;
        permissionContract = _permissionContract;
    }

    function deployEntity(string calldata name) external payable {
        Entity e = new Entity(name, badgeContract, permissionContract);
        entities[address(e)] = name;
    }

    function isRegistered(address addr) external pure returns (bool) {
        return (keccak256(abi.encodePacked(addr)) ==
            keccak256(abi.encodePacked("")));
    }
}
