//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./PermissionToken.sol";

contract Entity is ReentrancyGuard {
    string public entityName;
    address public genesisUserAddress;
    mapping(address => UserData) public superUsers;
    mapping(address => UserData) public genericUsers;

    constructor(string memory _entityName) {
        console.log("Deployed new entity:", _entityName);
        entityName = _entityName;
        genesisUserAddress = msg.sender;
    }

    modifier genUserOnly() {
        require(
            msg.sender == genesisUserAddress,
            "Sender has no genesis user privilege"
        );
        _;
    }

    modifier superUsersOnly() {
        require(
            (superUsers[msg.sender].exists) ||
                (msg.sender == genesisUserAddress),
            "Sender has no super user privilege"
        );
        _;
    }

    // function assignSuperUser(address _userAddress)
    //     public
    //     genUserOnly
    //     nonReentrant
    //     returns (bool)
    // {
    //     if (superUsers[_userAddress].exists) {
    //         return false;
    //     }

    //     superUsers[_userAddress] = UserData(_userAddress, );
    //     return true;
    // }
}

struct UserData {
    address assignedBy;
    address nftAddress;
    bool exists;
}
