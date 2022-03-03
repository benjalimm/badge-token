//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IBadgeRegistry {
    function isRegistered(address addr) external view returns (bool);

    function deployEntity(string calldata name, string calldata genesisTokenURI)
        external
        payable;

    function getPermContract() external view returns (address);

    event EntityDeployed(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );
}
