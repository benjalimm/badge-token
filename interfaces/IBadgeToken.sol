pragma solidity ^0.8.4;

interface IBadgeToken {
    function mintBadge(
        address to,
        uint256 level,
        string calldata tokenURI
    ) external;

    function burnAsEntity(uint256 tokenId) external;

    function getDateForBadge(uint256 tokenId) external view returns (uint256);

    function setNewEntity(address _entity) external;

    function getDemeritPoints() external view returns (uint256);

    function getEntity() external view returns (address);
}
