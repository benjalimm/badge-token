pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PermissionToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _ids;
    address public ent;

    constructor(address _ent, string memory _name)
        ERC721(join(_name, " - Permission Tokens"), join(_name, "_PERMISSION"))
    {
        ent = _ent;
    }

    function join(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function createToken(address _owner, string memory tokenURI)
        external
        payable
        returns (uint256)
    {
        require(msg.sender == ent, "Not allowed");

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
