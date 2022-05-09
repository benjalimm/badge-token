//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Entity.sol";
import "./BadgeToken.sol";
import "./PermissionToken.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../interfaces/IBadgeRegistry.sol";

contract BadgeRegistry is BaseRelayRecipient, IBadgeRegistry {
    mapping(address => bool) public entities;
    address public permissionContract;
    string public override versionRecipient = "2.2.0";
    uint256 public badgePrice = 5;
    uint256 public levelMultiplier = 2;
    address public owner;

    constructor(address _forwarder) {
        _setTrustedForwarder(_forwarder);
        owner = msg.sender;
    }

    function deployEntity(string calldata name, string calldata genesisTokenURI)
        external
        payable
        override
    {
        // Entity e = new Entity(name, address(this), trustedForwarder());
        // entities[address(e)] = true;
        // e.assignGenesisTokenHolder(_msgSender(), genesisTokenURI);
        // emit EntityDeployed(address(e), name, _msgSender());
    }

    function isRegistered(address addr) external view override returns (bool) {
        return entities[addr];
    }

    modifier ownerOnly() {
        require(_msgSender() == owner, "Only owner can call this");
        _;
    }

    function setBadgePrice(uint256 _price) external ownerOnly {
        badgePrice = _price;
    }

    function getBadgePrice(uint256 level) external view returns (uint256) {
        return badgePrice * (levelMultiplier ^ level);
    }
}
