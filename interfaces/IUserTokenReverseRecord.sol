pragma solidity ^0.8.0;

interface IUserTokenReverseRecord {
    error Unauthorized(string message);

    function addBadgeReverseRecord(address user, address registry) external;

    function addPermTokenReverseRecord(address user, address registry) external;

    function getBadgeReverseRecord(address user)
        external
        view
        returns (address[] memory);

    function getPermTokenReverseRecord(address user)
        external
        view
        returns (address[] memory);

    function hasUserBeenAwardedByBadgeToken(address user, address badgeToken)
        external
        view
        returns (bool);

    function doesUserHavePermissionToken(address user, address permToken)
        external
        view
        returns (bool);
}
