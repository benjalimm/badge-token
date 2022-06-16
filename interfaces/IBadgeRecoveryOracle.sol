pragma solidity ^0.8.4;

interface IBadgeRecoveryOracle {
    function getRecoveryAddress(address _address)
        external
        view
        returns (address);

    function setRecoveryAddress(address _recoveryAddress) external;
}
