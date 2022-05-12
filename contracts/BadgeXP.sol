pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IBadgeXP.sol";

contract BadgeXP is IERC20, IERC20Metadata, IBadgeXP {
    uint256 public totalXP;
    mapping(address => uint256) public balance;
    address public badgeRegistry;
    uint256 public baseXP = 10;

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

    function calculateXP(uint256 level) private view returns (uint256) {
        uint256 levelMultiplierX1000 = IBadgeRegistry(badgeRegistry)
            .getLevelMultiplierX1000();
        return baseXP * ((levelMultiplierX1000 ^ level) / (1000 ^ level));
    }

    function mint(uint256 level, address recipient)
        external
        override
        registeredEntitiesOnly
    {
        uint256 xp = calculateXP(level);
        balance[recipient] += xp;
        totalXP += xp;
        emit Transfer(address(0), recipient, xp);
    }

    function burn(uint256 amount, address recipient)
        external
        override
        registeredEntitiesOnly
    {
        balance[recipient] -= amount;
        totalXP -= amount;
        emit Transfer(recipient, address(0), amount);
    }
}
