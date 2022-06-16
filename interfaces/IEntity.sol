pragma solidity ^0.8.4;
import "./IPermissionToken.sol";

interface IEntity {
    // ** Functions ** \\
    function getBadgeRegistry() external view returns (address);

    function getPermissionToken() external view returns (address);

    function getBadgeToken() external view returns (address);

    function calculateMinStake(uint256 demeritPoints)
        external
        view
        returns (uint256);
}
