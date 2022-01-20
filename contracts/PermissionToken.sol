pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";

contract PermissionToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public entityAddress;

    constructor(address _entityAddress, string memory _entityName)
        ERC721(
            join(_entityName, " - Permission Tokens"),
            join(_entityName, "_PERMISSION")
        )
    {
        entityAddress = _entityAddress;
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
        require(
            msg.sender == entityAddress,
            "Only the entity can create tokens"
        );

        //1. Increment the id counter
        _tokenIds.increment();

        //2. Assign the id to the tokenURI
        uint256 newItemId = _tokenIds.current();

        //3. Mint the token
        _mint(_owner, newItemId);

        //4. Set the tokenURI
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}
