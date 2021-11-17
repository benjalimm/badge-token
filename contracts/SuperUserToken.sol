//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";
import "./BadgeV1.sol";
import "./Structs.sol";

contract SuperUserToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => mapping(address => Owner)) public orgToOwners;

    constructor() ERC721("Badge - Super user token", "BADGE_SUPER") {}

    modifier genUserOnly(address orgAddress) {
        Entity entity = Entity(orgAddress);
        require(
            entity.genesisUserAddress() == msg.sender,
            "Sender is not a genesis user"
        );
        _;
    }

    function mintSuperUserToken(
        string memory tokenURI,
        address superUserAddress,
        address orgAddress,
        address badgeAddress
    ) public payable genUserOnly(orgAddress) returns (uint256) {
        require(
            !orgToOwners[orgAddress][superUserAddress].exists,
            "User already exists in org"
        );
        uint256 data = createToken(tokenURI, superUserAddress);
        orgToOwners[orgAddress][superUserAddress] = Owner(
            superUserAddress,
            true
        );

        Entity entity = Entity(orgAddress);
        entity.assignSuperUser(superUserAddress, msg.sender, badgeAddress);

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
