pragma solidity ^0.8.0;

import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IUserTokenReverseRecordOracle.sol";

contract UserTokenReverseRecordOracle is IUserTokenReverseRecordOracle {
    address public owner;

    /* Badge token reverse records */
    mapping(address => address[]) public badgeTokenListReverseRecord;
    mapping(address => mapping(address => uint256))
        public badgeTokenReverseRecordIndex; // Store index of Badge reverse record

    /* Permission token reverse records */
    mapping(address => address[]) public permTokenListReverseRecord;
    mapping(address => mapping(address => uint256))
        public permTokenReverseRecordIndex; // Store index of permTokenReverseRecord

    /* Certified registries that hold registered entities */
    mapping(address => bool) public certifiedRegistries;

    modifier auth(address registry) {
        // 1. Make sure registry is certified
        if (!certifiedRegistries[registry])
            revert Unauthorized("Not a certified registry");

        // 2. Make sure sender is a registered entity
        if (!IBadgeRegistry(registry).isRegistered(msg.sender))
            revert Unauthorized("Not a registered entity");
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert Unauthorized("Only owner can call this");
        _;
    }

    constructor(address badgeRegistry) {
        owner = msg.sender;
        certifiedRegistries[badgeRegistry] = true;
    }

    function setRegistryCertified(address registry, bool certified)
        external
        onlyOwner
    {
        certifiedRegistries[registry] = certified;
    }

    function doesBadgeReverseRecordExists(address user, address token)
        public
        view
        override
        returns (bool)
    {
        uint256 index = badgeTokenReverseRecordIndex[user][token];
        return badgeTokenListReverseRecord[user][index] == token;
    }

    function doesPermReverseRecordExists(address user, address token)
        public
        view
        override
        returns (bool)
    {
        uint256 index = permTokenReverseRecordIndex[user][token];
        return badgeTokenListReverseRecord[user][index] == token;
    }

    function addBadgeReverseRecord(address user, address registry)
        external
        override
        auth(registry)
    {
        if (!doesBadgeReverseRecordExists(user, msg.sender)) {
            badgeTokenListReverseRecord[user].push(msg.sender);
            badgeTokenReverseRecordIndex[user][msg.sender] =
                badgeTokenListReverseRecord[user].length -
                1;
        }
    }

    function addPermTokenReverseRecord(address user, address registry)
        external
        override
        auth(registry)
    {
        if (!doesPermReverseRecordExists(user, msg.sender)) {
            permTokenListReverseRecord[user].push(msg.sender);
            permTokenReverseRecordIndex[user][msg.sender] =
                permTokenListReverseRecord[user].length -
                1;
        }
    }

    function removeBadgeReverseRecord(address user, address registry)
        external
        override
        auth(registry)
    {
        if (doesBadgeReverseRecordExists(user, msg.sender)) {
            uint256 index = badgeTokenReverseRecordIndex[user][msg.sender];
            // We simply set the value to address(0), as rearraging the indexes would require too much gas.
            badgeTokenListReverseRecord[user][index] = address(0);
        }
    }

    function removePermReverseRecord(address user, address registry)
        external
        override
        auth(registry)
    {
        if (doesPermReverseRecordExists(user, msg.sender)) {
            uint256 index = permTokenReverseRecordIndex[user][msg.sender];
            permTokenListReverseRecord[user][index] = address(0);
        }
    }

    function getBadgeReverseRecord(address user)
        external
        view
        override
        returns (address[] memory)
    {
        return badgeTokenListReverseRecord[user];
    }

    function getPermTokenReverseRecord(address user)
        external
        view
        override
        returns (address[] memory)
    {
        return permTokenListReverseRecord[user];
    }
}
