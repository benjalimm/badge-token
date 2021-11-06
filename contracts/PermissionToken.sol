//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

enum PermissionType {
    GENESIS,
    SUPER,
    GENERIC
}

contract PermissionToken is ERC721 {
    PermissionType public permType;
    address public orgAddress;

    constructor(address _orgAddress, PermissionType _permType)
        ERC721("Badge permission token", "BADGE_PERM")
    {
        orgAddress = _orgAddress;
        permType = _permType;
    }
}
