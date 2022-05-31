pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IPermissionToken.sol";

contract PermissionToken is ERC721URIStorage, IPermissionToken {
    using Counters for Counters.Counter;
    Counters.Counter private _ids;
    address public badgeRegistry;
    address public entityAddress;
    mapping(address => PermLevel) public permissionTokenHolders;

    constructor(string memory _entityName, address _entityAddress)
        ERC721(
            string(abi.encodePacked(_entityName, " - Permission token")),
            string(abi.encodePacked(_entityName, "_PERM_TOKEN"))
        )
    {
        entityAddress = _entityAddress;
    }

    modifier entityOnly() {
        require(
            msg.sender == entityAddress,
            "Only entity can access this method"
        );
        _;
    }

    function privateMint(address _owner, string memory tokenURI)
        private
        returns (uint256)
    {
        //1. Increment the id counter
        _ids.increment();

        //2. Assign the id to the tokenURI
        uint256 newItemId = _ids.current();

        //3. Mint the token
        _mint(_owner, newItemId);

        //4. Set the tokenURI
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
