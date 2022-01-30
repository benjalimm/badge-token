pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";
import "./BadgeRegistry.sol";

contract BadgeToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping tokenId to time minted
    mapping(uint256 => uint256) private _idToDateMinted;
    address public badgeRegistry;

    constructor(address _badgeRegistry) ERC721("Badge.", "BADGE") {
        badgeRegistry = _badgeRegistry;
    }

    modifier entityRegistered() {
        bool registered = BadgeRegistry(badgeRegistry).isRegistered(msg.sender);
        require(registered, "Entity is not registered");
        _;
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
        Entity(msg.sender).incrementDemeritPoints();
        emit BadgeBurned(msg.sender, true);
    }

    function mintBadge(address userId, string memory tokenURI)
        external
        payable
        entityRegistered
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(userId, newItemId);
        _setTokenURI(newItemId, tokenURI);
        emit Transfer(msg.sender, userId, newItemId);
    }
}
