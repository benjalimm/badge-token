pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IPermissionToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntity.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";
import "./NonTransferableERC721.sol";

contract PermissionToken is NonTransferableERC721, IPermissionToken {
    using Counters for Counters.Counter;

    Counters.Counter private _ids;

    address public badgeRegistry;
    address public entityAddress;
    mapping(address => PermLevel) public permissionTokenHolders;

    constructor(string memory _entityName, address _entityAddress)
        NonTransferableERC721(
            concat(_entityName, " - Permission token"),
            concat(_entityName, "_PERM_TOKEN")
        )
    {
        entityAddress = _entityAddress;
    }

    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    modifier entityOnly() {
        if (msg.sender != entityAddress)
            revert Unauthorized("Only entity can call this");
        _;
    }

    function privateMint(address _owner, string memory tokenURI)
        private
        returns (uint256)
    {
        // 1. Increment the id counter
        _ids.increment();

        // 2. Assign the id to the tokenURI
        uint256 newItemId = _ids.current();

        // 3. Mint the token
        _mint(_owner, newItemId);

        // 4. Set the tokenURI
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    function mintAsEntity(
        address _owner,
        PermLevel level,
        string memory tokenURI
    ) external payable override entityOnly returns (uint256) {
        permissionTokenHolders[_owner] = level;
        return privateMint(_owner, tokenURI);
    }

    function getEntityAddress() external view override returns (address) {
        return entityAddress;
    }

    function getPermStatusForUser(address user)
        external
        view
        override
        returns (PermLevel)
    {
        return permissionTokenHolders[user];
    }
}
