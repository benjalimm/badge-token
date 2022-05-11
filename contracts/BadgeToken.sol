pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";
import "../interfaces/IBadgeToken.sol";

contract BadgeToken is ERC721URIStorage, IBadgeToken {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping tokenId to time minted
    mapping(uint256 => uint256) private _idToDateMinted;
    address public entity;

    constructor(address _entity, string memory _name)
        ERC721(concat(_name, " - Badges"), "BADGE")
    {
        entity = _entity;
    }

    modifier entityOnly() {
        require(msg.sender == entity, "Only entity can access this method");
        _;
    }

    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(false, "Badges are non-transferrable");
    }

    function burnWithPrejudice(uint256 tokenId) external payable override {
        require(msg.sender == ownerOf(tokenId), "Only owner can burn badge");
        require(
            (block.timestamp - _idToDateMinted[tokenId]) <= 604800,
            "Not allowed after 7 days"
        );
        _burn(tokenId);
        Entity(entity).incrementDemeritPoints();
        emit BadgeBurned(msg.sender, true);
    }

    function mintBadge(address _to, string calldata _tokenURI)
        external
        payable
        override
        entityOnly
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
    }
}
