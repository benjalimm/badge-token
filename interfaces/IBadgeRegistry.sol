//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IBadgeRegistry {
    function isRegistered(address addr) external view returns (bool);

    function registerEntity(address entityAddress) external;

    event EntityDeployed(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );

    event EntityRegistered(address entityAddress);
}
