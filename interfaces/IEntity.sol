pragma solidity ^0.8.4;
import "./IPermissionToken.sol";

interface IEntity {
    // ** Errors ** \\
    error Unauthorized(string message);
    error Failure(string message);

    // ** Events ** \\
    event PermissionTokenAssigned(
        address entityAddress,
        address assigner,
        PermLevel assignerLevel,
        address assignee,
        PermLevel assigneeLevel
    );

    event EntityMigrated(address newEntity);
    event TokensMigrated(address newBadgeToken, address newPermToken);

    // ** Functions ** \\
    function mintBadge(
        address to,
        uint256 level,
        string calldata _tokenURI
    ) external payable;

    function getBadgeRegistry() external view returns (address);

    function assignPermissionToken(
        address assignee,
        PermLevel level,
        string calldata tokenURI
    ) external;

    function getPermissionToken() external view returns (address);

    function getBadgeToken() external view returns (address);
}
