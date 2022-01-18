pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BadgeToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public entityAddress;

    constructor(address _entityAddress, string memory _entityName)
        ERC721(join(_entityName, " - Badges"), join(_entityName, "_BADGE"))
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

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(false, "Badges are unique to a user and cannot be transferred");
    }
}
