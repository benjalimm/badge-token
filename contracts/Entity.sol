//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Entity is ReentrancyGuard, Ownable {
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

    function createSuperUser(address _walletAddress)
        public
        payable
        genUserOnly
        nonReentrant
    {}
}

struct UserData {
    address assignedBy;
    address nftAddress;
    bool exists;
}
