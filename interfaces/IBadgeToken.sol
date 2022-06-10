pragma solidity ^0.8.0;

interface IBadgeToken {
    event BadgeMinted(
        address entity,
        uint256 tokenId,
        uint256 level,
        string tokenURI
    );

    event BadgeBurned(address entityAddress, bool withPrejudice);

    error Unauthorized(string message);
    error Failure(string message);

    function burn(uint256 tokenId, bool withPrejudice) external payable;

    function mintBadge(
        address _to,
        uint256 level,
        string calldata _tokenURI
    ) external payable;

    function setNewEntity(address _entity) external;

    function getDemeritPoints() external view returns (uint256);

    function getEntity() external view returns (address);
}
