pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntity.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";
import "./NonTransferableERC721.sol";

contract BadgeToken is NonTransferableERC721, IBadgeToken {
    using Counters for Counters.Counter;

    // ** Token info ** \\
    Counters.Counter private _tokenIds;
    mapping(uint256 => uint256) private tokenIdToLevel;
    mapping(uint256 => uint256) private idToDateMinted;
    Counters.Counter public demeritPoints;

    // ** Pertinent addresses ** \\
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

    // ** Modifiers ** \\
    modifier entityOnly() {
        if (msg.sender != entity)
            revert Unauthorized("Only entity can call this");
        _;
    }

    // ** Setter functions ** \\
    function setNewEntity(address _entity) external override entityOnly {
        entity = _entity;
    }

    // ** Convenience functions ** \\
    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    // ** Token functions ** \\
    function burn(uint256 tokenId, bool withPrejudice)
        external
        payable
        override
    {
        if (msg.sender != ownerOf(tokenId))
            revert Unauthorized("Only owner can burn badge");

        if (withPrejudice) {
            if ((block.timestamp - idToDateMinted[tokenId]) <= 604800)
                revert Unauthorized(
                    "burnWithPrejudice unauthorized after 7 days"
                );
            demeritPoints.increment();
        }

        _burn(tokenId);
        emit BadgeBurned(msg.sender, withPrejudice);
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

    // ** Getter functions ** \\
    function getDemeritPoints() public view override returns (uint256) {
        return demeritPoints.current();
    }

    function getEntity() public view override returns (address) {
        return entity;
    }
}
