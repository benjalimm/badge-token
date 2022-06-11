pragma solidity ^0.8.4;
import "hardhat/console.sol";

enum PermLevel {
    ADMIN,
    SUPER_ADMIN,
    GENESIS
}

interface IPermissionToken {
    error Unauthorized(string message);
    error Failure(string message);

    function mintAsEntity(
        address _owner,
        PermLevel level,
        string memory tokenURI
    ) external payable returns (uint256);

    function getPermStatusForUser(address user)
        external
        view
        returns (PermLevel);

    function setNewEntity(address _entity) external;

    function getEntity() external view returns (address);
}
