pragma solidity ^0.8.0;

interface IUserTokenReverseRecordOracle {
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

    function doesBadgeReverseRecordExists(address user, address badgeToken)
        external
        view
        returns (bool);

    function doesPermReverseRecordExists(address user, address permToken)
        external
        view
        returns (bool);

    function removeBadgeReverseRecord(address user, address registry) external;

    function removePermReverseRecord(address user, address registry) external;
}
