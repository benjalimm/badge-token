//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

interface IEntityFactory {
    function createEntity(
        string calldata _entityName,
        address genesisUser,
        string calldata genesisTokenURI
    ) external returns (address);
}
