pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IEntity.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";
import "./NonTransferableERC721.sol";
import "./CommonErrors.sol";

contract BadgeToken is NonTransferableERC721, IBadgeToken {
    using Counters for Counters.Counter;

    // ** Events ** \\
    event StakeReceived(uint256 amount, bool minimumStakeMet);

    event BadgeMinted(
        address entity,
        uint256 tokenId,
        uint256 level,
        string tokenURI
    );

    event BadgeBurned(bool byEntity, bool withPrejudice);

    // ** Structs ** \\
    struct BadgeInfo {
        uint256 level;
        uint256 timestamp;
        uint256 xp;
    }

    // ** Token info ** \\
    Counters.Counter private _tokenIds;
    mapping(uint256 => BadgeInfo) private idToBadgeInfo;
    Counters.Counter public demeritPoints;

    // ** Pertinent addresses ** \\
    address public entity;
    address public recoveryOracle;

    // ** Constants ** \\
    uint256 public constant TIME_ALLOWED_TO_BURN = 2592000; // 30 days

    constructor(
        address _entity,
        address _recoveryOracle,
        string memory name_
    ) NonTransferableERC721(concat(name_, " - Badges"), "BADGE") {
        entity = _entity;
        recoveryOracle = _recoveryOracle;
    }

    // ** Receive / Fallback ** \\
    receive() external payable {
        emit StakeReceived(
            msg.value,
            msg.value >=
                IEntity(entity).calculateMinStake(demeritPoints.current())
        );
    }

    fallback() external payable {
        emit StakeReceived(
            msg.value,
            msg.value >=
                IEntity(entity).calculateMinStake(demeritPoints.current())
        );
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
    function mintBadge(
        address to,
        uint256 level,
        uint256 xp,
        string calldata tokenURI
    ) external override entityOnly {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // Construct info
        idToBadgeInfo[newItemId] = BadgeInfo(level, block.timestamp, xp);

        emit BadgeMinted(address(this), newItemId, level, tokenURI);
    }

    function burn(uint256 tokenId, bool withPrejudice) external {
        // 1. Check ownership
        if (msg.sender != ownerOf(tokenId))
            revert Unauthorized("Only owner can burn badge");

        // 2. We burn the Badge before doing anything else
        /// This prevents any possible re-entrancy attacks if the Badge is burned with prejudice (As funds are compensated to the burning entity)
        _burn(tokenId);

        // 3. Check if burned with prejudice

        /// Recipients have up to 30 days to burn token with prejudice
        /// Burning with prejudice gives the issuer a demerit point + compensates recipients 50% portion of the stake
        /// An increase in demerit points results in a higher minimum stake
        if (withPrejudice) {
            if (
                (block.timestamp - getTimestampForBadge(tokenId)) >
                TIME_ALLOWED_TO_BURN
            )
                revert Unauthorized(
                    "burnWithPrejudice unauthorized after 30 days"
                );

            // Increment demerit points -> Increases minimum stake required
            demeritPoints.increment();

            // Send half of stake to the recipient
            msg.sender.call{value: address(this).balance / 2}("");
        }

        emit BadgeBurned(false, withPrejudice);
    }

    function burnAsEntity(uint256 tokenId) external override entityOnly {
        uint256 dateMinted = getTimestampForBadge(tokenId);
        if (dateMinted == 0) revert Failure("Badge not minted");

        // 2. Calculate time since Badge minted
        uint256 timeSinceMinted = block.timestamp - dateMinted;

        if (timeSinceMinted > TIME_ALLOWED_TO_BURN)
            revert Unauthorized("Badge can only be burned for first 30 days");

        _burn(tokenId);
        emit BadgeBurned(true, false);
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 32))
        }
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

        // 3. Check if recovery address matches sender
        if (bytesToAddress(result) == msg.sender) {
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

    function getTimestampForBadge(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return idToBadgeInfo[tokenId].timestamp;
    }

    function getXPForBadge(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return idToBadgeInfo[tokenId].xp;
    }
}
