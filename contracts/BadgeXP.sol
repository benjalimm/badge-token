pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../interfaces/IBadgeRegistry.sol";

contract BadgeXP is IERC20, IERC20Metadata {
    uint256 public totalXP;
    mapping(address => uint256) public balance;
    address public badgeRegistry;

    constructor(address _badgeRegistry) {
        badgeRegistry = _badgeRegistry;
    }

    function totalSupply() external view override returns (uint256) {
        return totalXP;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balance[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return false;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {}

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return false;
    }

    function name() external view override returns (string memory) {
        return "Badge XP points";
    }

    function symbol() external view override returns (string memory) {
        return "BXP";
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    modifier registeredEntitiesOnly() {
        require(
            IBadgeRegistry(badgeRegistry).isRegistered(msg.sender),
            "Registered entities only"
        );
        _;
    }

    function mint(uint256 amount, address recipient)
        external
        registeredEntitiesOnly
    {
        balance[recipient] += amount;
        totalXP += amount;
        emit Transfer(address(0), recipient, amount);
    }

    function burn(uint256 amount, address recipient)
        external
        registeredEntitiesOnly
    {
        balance[recipient] -= amount;
        totalXP -= amount;
        emit Transfer(recipient, address(0), amount);
    }
}
