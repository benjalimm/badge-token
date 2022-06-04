//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IBadgeRegistry {
    enum EntityReverseRecordType {
        BadgeToken,
        PermissionToken
    }

    event EntityRegistered(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );

    event EntityFactorySet(address entityFactory);

    event BadgeTokenFactorySet(address badgeTokenFactory);

    event PermissionTokenFactorySet(address permissionTokenFactory);

    event BadgeXPTokenSet(address badgeXPToken);

    event BadgePriceCalculatorSet(address badgePriceCalculator);

    event RecoveryOracleSet(address recoveryOracle);

    function isRegistered(address addr) external view returns (bool);

    function registerEntity(
        string calldata entityName,
        string calldata genesisTokenURI
    ) external;

    function getBadgeTokenFactory() external view returns (address);

    function getEntityFactory() external view returns (address);

    function getPermissionTokenFactory() external view returns (address);

    function getBadgeXPToken() external view returns (address);

    function getBadgePrice(uint256 level) external view returns (uint256);

    function getLevelMultiplierX1000() external view returns (uint256);

    function getSafe() external view returns (address);

    function getRecoveryOracle() external view returns (address);
}
