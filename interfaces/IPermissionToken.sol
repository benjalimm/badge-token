pragma solidity ^0.8.4;
import "hardhat/console.sol";

enum PermLevel {
    ADMIN,
    SUPER_ADMIN,
    GENESIS
}

interface IPermissionToken {
    // ** Errors ** \\
    error Unauthorized(string message);
    error Failure(string message);

    // ** Events ** \\

    function mintAsEntity(
        address _owner,
        PermLevel level,
        string memory tokenURI
    ) external payable returns (uint256);

    function getPermStatusForAdmin(address admins)
        external
        view
        returns (PermLevel);

    function setNewEntity(address _entity) external;

    function getEntity() external view returns (address);

    function revokePermission(address _owner) external
}
