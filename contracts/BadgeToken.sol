pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntity.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";
import "./NonTransferableERC721.sol";

contract BadgeToken is NonTransferableERC721, IBadgeToken {
    using Counters for Counters.Counter;

    // Token id
    Counters.Counter private _tokenIds;

    // Mapping tokenId to time minted
    mapping(uint256 => uint256) private tokenIdToLevel;
    mapping(uint256 => uint256) private idToDateMinted;
    address public entity;
    address public recoveryOracle;

    constructor(
        address _entity,
        address _recoveryOracle,
        string memory name_
    ) NonTransferableERC721(concat(name_, " - Badges"), "BADGE") {
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

    function recover(uint256 id) external {
        // 1. Get owner of id
        address owner = ownerOf(id);

        // 2. Get recovery oracle address
        (bool success, bytes memory result) = address(recoveryOracle).call(
            abi.encodeWithSelector(
                IBadgeRecoveryOracle.getRecoveryAddress.selector,
                owner
            )
        );

        if (!success) revert Failure("Call to recovery oracle failed");

        // 3. Convert bytes to address
        address recoveryAddress;
        assembly {
            recoveryAddress := mload(add(result, 32))
        }
        // 4. Ensure recovery address has been set
        if (recoveryAddress == msg.sender) {
            _balances[owner] -= 1;
            _balances[msg.sender] += 1;
            _owners[id] = msg.sender;
            emit Transfer(owner, msg.sender, id);
        } else {
            revert Unauthorized("Only recovery address can recover badges");
        }
    }
}
