pragma solidity ^0.8.0;
import "./BadgeToken.sol";
import "../interfaces/IBadgeTokenFactory.sol";

contract BadgeTokenFactory is IBadgeTokenFactory {
    function createBadgeToken(string calldata entityName)
        external
        override
        returns (address)
    {
        address tokenAddress = address(new BadgeToken(msg.sender, entityName));
        emit BadgeTokenDeployed(entityName, msg.sender, tokenAddress);
        return tokenAddress;
    }
}
