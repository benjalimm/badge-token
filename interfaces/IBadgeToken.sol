pragma solidity ^0.8.4;

interface IBadgeToken {
    function mintBadge(
        address to,
        uint8 level,
        uint256 xp,
        string calldata tokenURI
    ) external;

    function burnAsEntity(uint256 tokenId) external;

    function resetBadgeURI(uint256 tokenId, string memory tokenURI) external;

    function getTimestampForBadge(uint256 tokenId)
        external
        view
        returns (uint256);

    function getXPForBadge(uint256 tokenId) external view returns (uint256);

    function setNewEntity(address _entity) external;

    function getDemeritPoints() external view returns (uint256);

    function getEntity() external view returns (address);
}
