pragma solidity ^0.8.0;
import "hardhat/console.sol";

struct Owner {
    address userAddress;
    bool exists;
}

struct UserData {
    address assigner;
    bool exists;
}

enum TokenType {
    GENESIS,
    SUPER_USER,
    BASIC_USER
}
