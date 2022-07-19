pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../interfaces/IBadgeRegistry.sol";
import "../interfaces/IBadgeXP.sol";
import "../interfaces/IBadgeRecoveryOracle.sol";
import "../interfaces/IBadgeXPOracle.sol";
import "../interfaces/IEntity.sol";
import "./CommonErrors.sol";

contract BadgeXP is IERC20, IERC20Metadata, IBadgeXP {
    string public constant version = "1.0";
    address public deployer;

    // ** ERC20 PROPERTIES ** \\
    uint256 public totalXP;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256))
        public userToBadgeTokenLedger; // User => BadgeToken => Amount // Keep track of tokens that each issuer awards to each user

    // ** RELATED CONTRACT ADDRESSES ** \\
    address public badgeRegistry;
    address public recoveryOracle;
    address public xpOracle;

    constructor(address _badgeRegistry, address _recoveryOracle) {
        deployer = msg.sender;
        badgeRegistry = _badgeRegistry;
        recoveryOracle = _recoveryOracle;
    }

    // ** MODIFIERS ** \\
    modifier registered(address _registry) {
        if (!IBadgeRegistry(badgeRegistry).isRegistryCertified(_registry))
            revert Unauthorized("Registry is not certified");
        if (!IBadgeRegistry(_registry).isRegistered(msg.sender))
            revert Unauthorized("Entity is not registered to registry");
        _;
    }

    modifier restrictBurnAmount(uint256 amount, address recipient) {
        // 1. Entity can only burn what they have issued
        address badgeToken = IEntity(msg.sender).getBadgeToken();
        uint256 totalTokensAwarded = userToBadgeTokenLedger[recipient][
            badgeToken
        ];
        require(amount <= totalTokensAwarded, "Not enough tokens");
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

    function name() external pure override returns (string memory) {
        return "Badge XP points";
    }

    function symbol() external pure override returns (string memory) {
        return "BXP";
    }

    function decimals() external pure override returns (uint8) {
        return 2;
    }

    function getXPForBadgeContractToRecipient(
        address badgeContract,
        address recipient
    ) external view override returns (uint256) {
        // Find out how much Badge contract (Entity) has awarded to recipient
        return userToBadgeTokenLedger[recipient][badgeContract];
    }

    // ** BadgeXP functions ** \\
    function mint(
        uint256 level,
        address recipient,
        address registry
    ) external override registered(registry) returns (uint256 xp) {
        // 1. Calculate Badge XP
        xp = IBadgeXPOracle(xpOracle).calculateXP(level);

        // 2. Increment balance
        balance[recipient] += xp;
        totalXP += xp;

        // 3. Keep track of how much each issuer has awarded to each user
        address badgeToken = IEntity(msg.sender).getBadgeToken();
        userToBadgeTokenLedger[recipient][badgeToken] += xp;
        emit Transfer(msg.sender, recipient, xp);
    }

    function burn(
        uint256 amount,
        address recipient,
        address registry
    )
        external
        override
        registered(registry)
        restrictBurnAmount(amount, recipient)
    {
        address badgeToken = IEntity(msg.sender).getBadgeToken();

        // 1. Decrement balance
        balance[recipient] -= amount;

        // 2. Decrement badge token specific ledger
        userToBadgeTokenLedger[recipient][badgeToken] -= amount;

        // 3. Decrement totalXP
        totalXP -= amount;
        emit Transfer(recipient, address(0), amount);
    }

    function resetXP(
        uint256 amount,
        address from,
        address to,
        address registry
    ) external override registered(registry) restrictBurnAmount(amount, from) {
        // 1. Decrement balance
        balance[from] -= amount;
        balance[to] += amount;

        address badgeToken = IEntity(msg.sender).getBadgeToken();

        // 2. Adjust the user to badge token ledger
        userToBadgeTokenLedger[from][badgeToken] -= amount;
        userToBadgeTokenLedger[to][badgeToken] += amount;
        emit Transfer(from, to, amount);
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

    // ** Setter functions ** \\
    function setXPOracle(address _xpOracle) external {
        if (msg.sender != deployer)
            revert Unauthorized("Only deployer can set");
        xpOracle = _xpOracle;
    }
}
