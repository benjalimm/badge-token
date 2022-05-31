pragma solidity ^0.8.0;
import "hardhat/console.sol";

enum PermLevel {
    ADMIN,
    SUPER_ADMIN,
    GENESIS
}

interface IPermissionToken {
    function getEntityAddress() external view returns (address);

    function mintAsEntity(
        address _owner,
        PermLevel level,
        string memory tokenURI
    ) external payable returns (uint256);

    function getPermStatusForUser(address user)
        external
        view
        returns (PermLevel);
}
