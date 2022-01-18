//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Entity.sol";
import "./BadgeV1.sol";
import "./Structs.sol";

contract GenesisToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => Owner) public orgToOwner;

    constructor() ERC721("Badge - Genesis token", "BADGE_GENESIS") {}

    event EntityDeployed(
        address entityAddress,
        string entityName,
        address genesisTokenHolder
    );

    function mintGenToken(
        string memory tokenURI,
        string memory entityName,
        address badgeAddress
    ) external payable returns (address) {
        BadgeV1 badge = BadgeV1(badgeAddress);
        Entity entity = badge.deployEntity(entityName);
        orgToOwner[address(entity)] = Owner(msg.sender, true);
        createToken(tokenURI, msg.sender);
        console.log("Entity address: ", address(entity));
        emit EntityDeployed(address(entity), entityName, msg.sender);
        return address(entity);
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
