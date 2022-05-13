pragma solidity ^0.8.0;

interface IBadgeToken {
    function burnWithPrejudice(uint256 tokenId) external payable;

    function mintBadge(
        address _to,
        uint256 level,
        string calldata _tokenURI
    ) external payable;

    event BadgeMinted(
        address entity,
        uint256 tokenId,
        uint256 level,
        string tokenURI
    );
    event BadgeBurned(address entityAddress, bool withPrejudice);
}
