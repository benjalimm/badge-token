//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./GenesisToken.sol";
import "./SuperUserToken.sol";
import "./BadgeV1.sol";
import "./Structs.sol";
import "./BadgeToken.sol";

contract Entity is ReentrancyGuard {
    using Counters for Counters.Counter;

    string public entityName;
    address public genesisUserAddress;
    mapping(address => UserData) public superUsers;
    mapping(address => UserData) public basicUsers;

    Counters.Counter public demeritPoints;
    BadgeToken public badgeTokenContact;

    constructor(string memory _entityName) {
        console.log("Deployed new entity:", _entityName);
        entityName = _entityName;
        genesisUserAddress = msg.sender;
        badgeTokenContact = new BadgeToken(address(this), _entityName);
    }

    modifier genUserOnly() {
        require(
            msg.sender == genesisUserAddress,
            "Sender has no genesis user privilege"
        );
        _;
    }

    modifier superUsersOnly() {
        require(
            (superUsers[msg.sender].exists) ||
                (msg.sender == genesisUserAddress),
            "Sender has no super user privilege"
        );
        _;
    }

    modifier superUserTokenOnly(address badgeAddress) {
        BadgeV1 badge = BadgeV1(badgeAddress);
        require(
            address(badge.superUserToken()) == msg.sender,
            "Sender is not super user token"
        );
        _;
    }

    modifier basicUserTokenOnly(address badgeAddress) {
        BadgeV1 badge = BadgeV1(badgeAddress);
        require(
            address(badge.basicUserToken()) == msg.sender,
            "Sender is not super user token"
        );
        _;
    }

    function assignSuperUser(
        address userAddress,
        address assigningAddress,
        address badgeAddress
    ) public nonReentrant superUserTokenOnly(badgeAddress) {
        superUsers[userAddress] = UserData(assigningAddress, true);
    }

    function assignBasicUser(
        address userAddress,
        address assigningAddress,
        address badgeAddress
    ) public nonReentrant basicUserTokenOnly(badgeAddress) {
        basicUsers[userAddress] = UserData(assigningAddress, true);
    }

    function doesUserExist(address userAddress, TokenType tokenType)
        public
        view
        returns (bool)
    {
        if (tokenType == TokenType.GENESIS) {
            return genesisUserAddress == userAddress;
        } else if (tokenType == TokenType.SUPER_USER) {
            return superUsers[userAddress].exists;
        } else if (tokenType == TokenType.BASIC_USER) {
            return basicUsers[userAddress].exists;
        } else {
            return false;
        }
    }

    function incrementDemeritPoints() external payable {
        require(
            msg.sender == address(badgeTokenContact),
            "Only badge token can increment demerit points"
        );
        demeritPoints.increment();
    }

    function getDemeritPoints() public view returns (uint256) {
        return demeritPoints.current();
    }
}
