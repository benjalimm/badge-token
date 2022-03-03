pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeRegistry.sol";

contract PermissionToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _ids;
    address public badgeRegistry;

    constructor(address _badgeRegistry)
        ERC721("Badge Permission Token", "BADGE_PERM")
    {
        badgeRegistry = _badgeRegistry;
    }

    modifier entityRegistered() {
        bool registered = IBadgeRegistry(badgeRegistry).isRegistered(
            msg.sender
        );
        require(registered, "Entity is not registered");
        _;
    }

    function mintToken(address _owner, string memory tokenURI)
        external
        entityRegistered
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
}
