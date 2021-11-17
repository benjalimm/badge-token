//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";
import "./BadgeV1.sol";
import "./Structs.sol";

contract BasicUserToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => mapping(address => Owner)) public orgToOwners;

    constructor() ERC721("Badge - Basic user token", "BADGE_BASIC") {}

    modifier genOrSuperUserOnly(address orgAddress) {
        Entity entity = Entity(orgAddress);
        bool isGenUser = (entity.genesisUserAddress() == msg.sender);
        bool isSuperUser = entity.doesUserExist(
            msg.sender,
            TokenType.SUPER_USER
        );
        require(isGenUser || isSuperUser, "Sender not gen or super user");
        _;
    }

    function mintBasicUserToken(
        string memory tokenURI,
        address basicUserAddress,
        address orgAddress,
        address badgeAddress
    ) public payable genOrSuperUserOnly(orgAddress) returns (uint256) {
        require(
            !orgToOwners[orgAddress][basicUserAddress].exists,
            "User already exists in org"
        );
        uint256 data = createToken(tokenURI, basicUserAddress);
        orgToOwners[orgAddress][basicUserAddress] = Owner(
            basicUserAddress,
            true
        );

        Entity entity = Entity(orgAddress);
        entity.assignBasicUser(basicUserAddress, msg.sender, badgeAddress);

        return data;
    }

    function createToken(string memory tokenURI, address _owner)
        internal
        returns (uint256)
    {
        //1. Increment the id counter
        _tokenIds.increment();

        //2. Assign the id to the tokenURI
        uint256 newItemId = _tokenIds.current();

        //3. Mint the token
        _mint(_owner, newItemId);

        //4. Set the tokenURI
        _setTokenURI(newItemId, tokenURI);

        //5. Allow the smart contract to interac
        console.log("SenderID:");
        console.log(msg.sender);

        return newItemId;
    }
}
