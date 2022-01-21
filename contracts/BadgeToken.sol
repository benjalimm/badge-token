pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";

contract BadgeToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public entityAddress;

    // Mapping tokenId to time minted
    mapping(uint256 => uint256) private _idToDateMinted;

    constructor(address _entityAddress, string memory _entityName)
        ERC721(join(_entityName, " - Badges"), join(_entityName, "_BADGE"))
    {
        entityAddress = _entityAddress;
    }

    modifier entityOnly() {
        require(msg.sender == entityAddress);
        _;
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
        require(false, "Transfer not allowed");
    }

    event BadgeBurned(address entityAddress, bool withPrejudice);

    function burnWithPrejudice(uint256 tokenId) external payable {
        require(msg.sender == ownerOf(tokenId), "Only owner can burn badge");
        require(
            (block.timestamp - _idToDateMinted[tokenId]) <= (60 * 60 * 24 * 7),
            "Not allowed after 7 days"
        );
        _burn(tokenId);
        Entity(entityAddress).incrementDemeritPoints();
        emit BadgeBurned(entityAddress, true);
    }

    function mintBadge(address userId, string memory tokenURI)
        external
        payable
        entityOnly
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(userId, newItemId);
        _setTokenURI(newItemId, tokenURI);
        emit Transfer(entityAddress, userId, newItemId);
    }
}
