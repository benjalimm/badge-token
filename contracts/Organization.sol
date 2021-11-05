//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Organization {
    string public orgName;
    address public genesisUserAddress;

    constructor(string memory _orgName) {
        console.log("Deployed new organization:", _orgName);
        orgName = _orgName;
        genesisUserAddress = msg.sender;
    }
}

// struct SuperUser {
//     address walletAddress;
//     address assignedBy;
//     address nftAddress
// }
