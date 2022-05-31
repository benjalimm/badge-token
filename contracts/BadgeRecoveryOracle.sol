pragma solidity ^0.8.0;
import "../interfaces/IBadgeRecoveryOracle.sol";

contract BadgeRecoveryOracle is IBadgeRecoveryOracle {
    mapping(address => address) public recoveryAddressMap;

    function isAddressSet(address _address) public view returns (bool) {
        return recoveryAddress[_address] != address(0);
    }

    function setRecoveryAddress(address _recoveryAddress) external {
        // 1. Make sure recovery address is not already set
        require(!isAddressSet(msg.sender), "Recovery address already set");

        // 2. Make sure sender and recoverAddress are different
        require(
            msg.sender != _recoveryAddress,
            "Recovery address same as sender"
        );

        recoveryAddress[msg.sender] = _recoveryAddress;
        emit RecoveryAddressSet(msg.sender, _recoveryAddress);
    }

    function getRecoveryAddress(address _address)
        external
        view
        returns (address)
    {
        return recoveryAddress[_address];
    }
}
