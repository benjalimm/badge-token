//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./IEntity.sol";

interface IEntityFactory {
    function createEntity(
        string calldata _entityName,
        address recoveryOracle,
        address genesisUser,
        string calldata genesisTokenURI,
        bool deployTokens
    ) external returns (IEntity);
}
