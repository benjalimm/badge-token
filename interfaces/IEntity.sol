pragma solidity ^0.8.4;
import "./IPermissionToken.sol";

interface IEntity {
    // ** Errors ** \\
    error Unauthorized(string message);
    error Failure(string message);

    // ** Functions ** \\
    function getBadgeRegistry() external view returns (address);

    function getPermissionToken() external view returns (address);

    function getBadgeToken() external view returns (address);

    function calculateMinStake(uint256 demeritPoints)
        external
        view
        returns (uint256);
}
