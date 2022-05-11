pragma solidity ^0.8.0;
import "hardhat/console.sol";

interface IPermissionToken {
    function getEntityAddress() external view returns (address);

    function mintAsEntity(address _owner, string memory tokenURI)
        external
        payable
        returns (uint256);
}
