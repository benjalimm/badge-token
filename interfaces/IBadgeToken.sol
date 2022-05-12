pragma solidity ^0.8.0;

interface IBadgeToken {
    function burnWithPrejudice(uint256 tokenId) external payable;

    function mintBadge(
        address _to,
        uint256 level,
        string calldata _tokenURI
    ) external payable;

    event BadgeBurned(address entityAddress, bool withPrejudice);
}
