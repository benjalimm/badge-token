pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntity.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";

contract BadgeToken is ERC721URIStorage, IBadgeToken {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping tokenId to time minted
    mapping(uint256 => uint256) private tokenIdToLevel;
    mapping(uint256 => uint256) private idToDateMinted;
    address public entity;
    address public recoveryOracle;

    constructor(
        address _entity,
        address _recoveryOracle,
        string memory _name
    ) ERC721(concat(_name, " - Badges"), "BADGE") {
        entity = _entity;
        recoveryOracle = _recoveryOracle;
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert TransferBlocked();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        revert TransferBlocked();
    }

    function burnWithPrejudice(uint256 tokenId) external payable override {
        require(msg.sender == ownerOf(tokenId), "Only owner can burn badge");
        require(
            (block.timestamp - idToDateMinted[tokenId]) <= 604800,
            "Not allowed after 7 days"
        );
        _burn(tokenId);
        IEntity(entity).incrementDemeritPoints();
        emit BadgeBurned(msg.sender, true);
    }

    function mintBadge(
        address _to,
        uint256 level,
        string calldata _tokenURI
    ) external payable override entityOnly {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        tokenIdToLevel[newItemId] = level;
        idToDateMinted[newItemId] = block.timestamp;

        emit BadgeMinted(address(this), newItemId, level, _tokenURI);
    }

    function recover(address from, uint256[] calldata ids) external {
        // 1. Get recovery oracle address
        (bool success, bytes memory result) = address(recoveryOracle).call(
            abi.encodeWithSelector(
                IBadgeRecoveryOracle.getRecoveryAddress.selector,
                from
            )
        );

        if (!success) revert Failure("Call to recovery oracle failed");

        // 1. 1 Convert bytes to address
        address recoveryAddress;
        assembly {
            recoveryAddress := mload(add(result, 32))
        }

        // 2. Ensure recovery address has been set
        if (recoveryAddress != msg.sender)
            revert Unauthorized("Only recovery address can recover badges");

        // 3. Loop through tokenIds and reset ids
        uint256 i = 0;
        uint256[] memory recoveredIds = new uint256[](ids.length);
        for (i = i; i < ids.length; i++) {
            uint256 id = ids[i];

            if (ownerOf(id) == from) {
                _transfer(from, msg.sender, id);
                recoveredIds[i] = id;
            }
        }
        emit RecoveryComplete(recoveredIds, msg.sender, recoveryAddress);
    }
}
