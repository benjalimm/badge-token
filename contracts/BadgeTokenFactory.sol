pragma solidity ^0.8.0;
import "./BadgeToken.sol";
import "../interfaces/IBadgeTokenFactory.sol";

contract BadgeTokenFactory is IBadgeTokenFactory {
    address public badgeRegistry;

    function createBadgeToken(string calldata _entityName)
        external
        override
        returns (address)
    {
        return address(new BadgeToken(msg.sender, _entityName));
    }
}
