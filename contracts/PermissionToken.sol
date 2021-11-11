//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PermissionToken is ERC721URIStorage {
    using Counters for Counters.Counter;

    enum PermissionType {
        GENESIS,
        SUPER,
        GENERIC
    }

    Counters.Counter private _tokenIds;
    PermissionType public permType;
    address public orgAddress;

    constructor(address _orgAddress, PermissionType _permType)
        ERC721("Badge permission token", "BADGE_PERM")
    {
        orgAddress = _orgAddress;
        permType = _permType;
    }

    function createToken(string memory tokenURI, address _owner)
        public
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
        setApprovalForAll(msg.sender, true);

        return newItemId;
    }
}
