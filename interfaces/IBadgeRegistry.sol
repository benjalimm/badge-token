//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IBadgeRegistry {
    function isRegistered(address addr) external view returns (bool);

    function registerEntity(
        string calldata entityName,
        string calldata genesisTokenURI
    ) external;

    function getBadgeTokenFactory() external view returns (address);

    function getEntityFactory() external view returns (address);

    function getPermissionTokenFactory() external view returns (address);

    function getBadgeXPToken() external view returns (address);

    event EntityRegistered(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );
}
