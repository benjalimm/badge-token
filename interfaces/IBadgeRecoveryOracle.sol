pragma solidity ^0.8.0;

interface IBadgeRecoveryOracle {
    event RecoveryAddressSet(address initialAddress, address recoveryAddress);
    error RecoveryAddressAlreadySet(address recoveryAddress);
    error RecoveryAddressSameAsSender();

    function getRecoveryAddress(address _address)
        external
        view
        returns (address);

    function setRecoveryAddress(address _recoveryAddress) external;
}