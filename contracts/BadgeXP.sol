pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IBadgeXP.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";

contract BadgeXP is IERC20, IERC20Metadata, IBadgeXP {
    uint256 public totalXP;
    mapping(address => uint256) public balance;
    address public badgeRegistry;
    address public recoveryOracle;
    uint256 public baseXP = 1000;

    constructor(address _badgeRegistry, address _recoveryOracle) {
        badgeRegistry = _badgeRegistry;
        recoveryOracle = _recoveryOracle;
    }

    // ** Modifiers ** \\
    modifier registered(address _registry) {
        if (!IBadgeRegistry(badgeRegistry).isRegistryCertified(_registry))
            revert Unauthorized("Registry is not certified");
        if (!IBadgeRegistry(_registry).isRegistered(msg.sender))
            revert Unauthorized("Entity is not registered to registry");
        _;
    }

    // ** ERC20 interface functions ** \\
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
    {
        return false;
    }

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
        return 2;
    }

    function calculateXP(uint256 level) private view returns (uint256) {
        if (level > 0) {
            uint256 xp = 0;
            for (uint256 i = level; i > 0; i--) {
                xp += baseXP + ((25 * xp) / 100);
            }
            return xp;
        } else {
            return 0;
        }
    }

    function mint(
        uint256 level,
        address recipient,
        address registry
    ) external override registered(registry) {
        uint256 xp = calculateXP(level);
        balance[recipient] += xp;
        totalXP += xp;
        emit Transfer(msg.sender, recipient, xp);
    }

    function burn(
        uint256 amount,
        address recipient,
        address registry
    ) external override registered(registry) {
        balance[recipient] -= amount;
        totalXP -= amount;
        emit Transfer(recipient, address(0), amount);
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function recover(address from) external {
        // 1. Get recovery address from recovery oracle
        (bool success, bytes memory result) = address(recoveryOracle).call(
            abi.encodeWithSelector(
                IBadgeRecoveryOracle.getRecoveryAddress.selector,
                from
            )
        );

        if (!success) revert Failure("Call to recovery oracle failed");

        // 2. Transfer if authorized
        if (bytesToAddress(result) == msg.sender) {
            uint256 value = balance[from];
            balance[msg.sender] = value;
            balance[from] = 0;
            emit Transfer(from, msg.sender, value);
        } else {
            revert Unauthorized("Only recovery address can recover Badge XP");
        }
    }
}
