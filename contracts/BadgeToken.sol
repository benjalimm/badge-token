pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IBadgeToken.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IBadgeXP.sol";
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
    event BadgeURIReset(string from, string to);
    event TokenSiteSet(string site);

    // ** Structs ** \\
    struct BadgeInfo {
        uint8 level;
        uint256 timestamp;
        uint256 xp;
    }

    // ** ** \\
    string public tokenSite;

    // ** TOKEN INFO ** \\
    Counters.Counter private _tokenIds;
    mapping(uint256 => BadgeInfo) private idToBadgeInfo;
    Counters.Counter public demeritPoints;

    // ** RELATED CONTRACTS ** \\
    address public entity;
    address public recoveryOracle;

    // ** CONSTANTS ** \\
    uint256 public constant TIME_ALLOWED_TO_BURN = 1296000; // 15 days

    constructor(
        address _entity,
        address _recoveryOracle,
        string memory name_
    ) NonTransferableERC721(concat(name_, " - Badges"), "BADGE") {
        entity = _entity;
        recoveryOracle = _recoveryOracle;
    }

    // ** RECEIVE / FALLBACK ** \\
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

    // ** MODIFIERS ** \\
    modifier entityOnly() {
        if (msg.sender != entity)
            revert Unauthorized("Only entity can call this");
        _;
    }

    modifier beforeTokenChangeTimeLimit(uint256 tokenId) {
        // Entities have up to 15 days to burn / make changes to the Badge
        uint256 dateMinted = getTimestampForBadge(tokenId);
        if (dateMinted == 0) revert Failure("Badge not minted");

        // 1. Calculate time since Badge minted
        uint256 timeSinceMinted = block.timestamp - dateMinted;

        // 2. Ensure time limit hasn't been reached (15 days)
        if (timeSinceMinted > TIME_ALLOWED_TO_BURN)
            revert Unauthorized("URI can only be reset for first 15 days");
        _;
    }

    // ** Setter functions ** \\
    function setNewEntity(address _entity) external override entityOnly {
        entity = _entity;
    }

    // ** CONVENIENCE FUNCTIONS ** \\
    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    function deleteBadgeInfo(uint256 id) private {
        delete idToBadgeInfo[id];
        delete _tokenURIs[id];
    }

    // ** BADGE TOKEN METHODS ** \\

    /// For entity to mint Badge ///
    function mintBadge(
        address to,
        uint8 level,
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

    /// For entity to (attempt to) burn Badge ///
    function burnAsEntity(uint256 tokenId)
        external
        override
        entityOnly
        beforeTokenChangeTimeLimit(tokenId)
    {
        // 1. Delete badge info
        deleteBadgeInfo(tokenId);

        // 2. Burn
        _burn(tokenId);
        emit BadgeBurned(true, false);
    }

    function resetBadgeURI(uint256 tokenId, string memory tokenURI)
        external
        override
        entityOnly
        beforeTokenChangeTimeLimit(tokenId)
    {
        // 1. Get old tokenURI
        string memory oldTokenURI = _tokenURIs[tokenId];

        // 2. Set new token URI
        _setTokenURI(tokenId, tokenURI);

        emit BadgeURIReset(oldTokenURI, tokenURI);
    }

    function resetBadgeRecipient(uint256 tokenId, address newRecipient)
        external
        override
        entityOnly
        beforeTokenChangeTimeLimit(tokenId)
    {
        require(newRecipient != address(0), "ERC721: mint to the zero address");

        address previousRecipient = _owners[tokenId];

        // 1. Reset balance
        _balances[previousRecipient] -= 1;
        _balances[newRecipient] += 1;

        // 2. Reset new owner
        _owners[tokenId] = newRecipient;

        emit Transfer(previousRecipient, newRecipient, tokenId);
    }

    /// For recipient to burn Badge ///
    function burn(uint256 tokenId, bool withPrejudice) external {
        // 1. Check ownership
        if (msg.sender != ownerOf(tokenId))
            revert Unauthorized("Only owner can burn badge");

        // 2. Get Badge info
        BadgeInfo memory info = idToBadgeInfo[tokenId];

        // 2. We burn the Badge before doing anything else
        /// This prevents any possible re-entrancy attacks if the Badge is burned with prejudice (As funds are compensated to the burning entity)
        _burn(tokenId);

        // 3. Attempt to burn associated Badge XP points
        try IEntity(entity).burnXPAsBadgeToken(info.xp, msg.sender) {
            // It succeeds - cool!
        } catch {
            // It didn't succeed - Whatever. It is more important for the sovereignty of the recipient that the burn function succeeds.
            // We do not want to rely on anything on the Entity level as that is modular + could be altered to prevent tokens from getting burnt.
        }

        // 4. Check if burned with prejudice

        /// Recipients have up to 30 days to burn token with prejudice
        /// Burning with prejudice gives the issuer a demerit point + compensates recipients 50% portion of the stake
        /// An increase in demerit points results in a higher minimum stake
        if (withPrejudice) {
            if ((block.timestamp - info.timestamp) > (TIME_ALLOWED_TO_BURN * 2))
                revert Unauthorized(
                    "burnWithPrejudice unauthorized after 30 days"
                );

            // Increment demerit points -> Increases minimum stake required
            demeritPoints.increment();

            // Send half of stake to the recipient
            msg.sender.call{value: address(this).balance / 2}("");
        }

        // 5. Delete badge info
        deleteBadgeInfo(tokenId);

        emit BadgeBurned(false, withPrejudice);
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

    function setTokenSite(string memory site) external override entityOnly {
        tokenSite = site;
        emit TokenSiteSet(site);
    }

    // ** GETTER FUNCTIONS ** \\
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
