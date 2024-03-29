pragma solidity ^0.8.4;
import "hardhat/console.sol";

interface IPermissionToken {
    function mintAsEntity(
        address assignee,
        uint256 level,
        string memory tokenURI
    ) external payable returns (uint256);

    function getPermStatusForAdmin(address admins)
        external
        view
        returns (uint256);

    function setNewEntity(address _entity) external;

    function getEntity() external view returns (address);

    function revokePermission(address _owner) external;
}
