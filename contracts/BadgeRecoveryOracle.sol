pragma solidity ^0.8.4;
import "../interfaces/IBadgeRecoveryOracle.sol";

contract BadgeRecoveryOracle is IBadgeRecoveryOracle {
    string public constant VERSION = "1.0";

    // ** Events ** \\
    event RecoveryAddressSet(address initialAddress, address recoveryAddress);

    // ** Errors ** \\
    error RecoveryAddressAlreadySet(address recoveryAddress);
    error RecoveryAddressSameAsSender();

    // ** REcovery a ** \\
    mapping(address => address) public recoveryAddressMap;

    function setRecoveryAddress(address _recoveryAddress) external override {
        // 1. Make sure recovery address is not already set
        address existingRecoveryAddress = recoveryAddressMap[msg.sender];
        if (existingRecoveryAddress != address(0)) {
            revert RecoveryAddressAlreadySet(existingRecoveryAddress);
        }

        // 2. Make sure sender and recoverAddress are different
        if (msg.sender == _recoveryAddress) {
            revert RecoveryAddressSameAsSender();
        }

        // 3. Set the recovery address
        recoveryAddressMap[msg.sender] = _recoveryAddress;
        emit RecoveryAddressSet(msg.sender, _recoveryAddress);
    }

    function getRecoveryAddress(address _address)
        external
        view
        override
        returns (address)
    {
        return recoveryAddressMap[_address];
    }
}
