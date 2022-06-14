pragma solidity ^0.8.4;
import "./IPermissionToken.sol";

interface IEntity {
    // ** Errors ** \\
    error Unauthorized(string message);
    error Failure(string message);

    // ** Functions ** \\
    function mintBadge(
        address to,
        uint256 level,
        string calldata _tokenURI
    ) external payable;

    function getBadgeRegistry() external view returns (address);

    function assignPermissionToken(
        address assignee,
        uint256 level,
        string calldata tokenURI
    ) external;

    function getPermissionToken() external view returns (address);

    function getBadgeToken() external view returns (address);
}
