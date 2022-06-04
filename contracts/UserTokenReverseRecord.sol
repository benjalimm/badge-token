pragma solidity ^0.8.0;

import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IUserTokenReverseRecord.sol";

contract UserTokenReverseRecord is IUserTokenReverseRecord {
    address public owner;

    mapping(address => address[]) public badgeTokenListReverseRecord;
    mapping(address => mapping(address => bool))
        public badgeTokenExistReverseRecord;
    mapping(address => address[]) public permTokenReverseRecord;
    mapping(address => mapping(address => bool))
        public permTokenExistReverseRecord;

    mapping(address => bool) public certifiedRegistries;

    modifier onlyBadgeEntity(address registry) {
        if (!certifiedRegistries[registry])
            revert Unauthorized("Not a certified registry");

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

    function addBadgeReverseRecord(address user, address registry)
        external
        override
        onlyBadgeEntity(registry)
    {
        if (!badgeTokenExistReverseRecord[user][msg.sender]) {
            badgeTokenListReverseRecord[user].push(msg.sender);
            badgeTokenExistReverseRecord[user][msg.sender] = true;
        }
    }

    function addPermTokenReverseRecord(address user, address registry)
        external
        override
        onlyBadgeEntity(registry)
    {
        if (!permTokenExistReverseRecord[user][msg.sender]) {
            permTokenReverseRecord[user].push(msg.sender);
            permTokenExistReverseRecord[user][msg.sender] = true;
        }
    }

    function removeBadgeReverseRecord(address user, address registry)
        external
        override
        onlyBadgeEntity(registry)
    {
        // if (badgeTokenExistReverseRecord[user][msg.sender]) {
        //     badgeTokenListReverseRecord[user].pull(msg.sender);
        //     badgeTokenExistReverseRecord[user][msg.sender] = false;
        // }
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
        return permTokenReverseRecord[user];
    }

    function hasUserBeenAwardedByBadgeToken(address user, address badgeToken)
        external
        view
        override
        returns (bool)
    {
        return badgeTokenExistReverseRecord[user][badgeToken];
    }

    function doesUserHavePermissionToken(address user, address permToken)
        external
        view
        override
        returns (bool)
    {
        return permTokenExistReverseRecord[user][permToken];
    }
}
