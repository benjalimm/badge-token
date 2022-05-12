pragma solidity ^0.8.0;

interface IEntity {
    function incrementDemeritPoints() external;

    function mintBadge(
        address to,
        uint256 level,
        string calldata _tokenURI
    ) external payable;

    function getBadgeRegistry() external view returns (address);

    function assignPermissionToken(
        address assignee,
        PermLevel level,
        string calldata tokenURI
    ) external;

    enum PermLevel {
        ADMIN,
        SUPER_ADMIN,
        GENESIS
    }

    event PermissionTokenAssigned(
        address entityAddress,
        address assigner,
        PermLevel assignerLevel,
        address assignee,
        PermLevel assigneeLevel
    );
}
