//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IBadgeRegistry {
    function isRegistered(address addr) external view returns (bool);

    function getBadgeTokenFactory() external view returns (address);

    function getEntityFactory() external view returns (address);

    function getPermissionTokenFactory() external view returns (address);

    function getBadgeXPToken() external view returns (address);

    function getBadgePrice(uint8 level) external view returns (uint256);

    function getSafe() external view returns (address);

    function getRecoveryOracle() external view returns (address);

    function isRegistryCertified(address _registry)
        external
        view
        returns (bool);

    function getDeployer() external view returns (address);

    function setTokenReverseRecords(address perm, address badge) external;

    function getBaseMinimumStake() external view returns (uint256);
}
