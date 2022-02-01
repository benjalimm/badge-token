pragma solidity ^0.8.0;

library strings {
    function concat(string memory _x, string memory _y)
        internal
        pure
        returns (string memory)
    {
        bytes memory _xBytes = bytes(_x);
        bytes memory _yBytes = bytes(_y);

        string memory _tmpValue = new string(_xBytes.length + _yBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint256 i;
        uint256 j;

        for (i = 0; i < _xBytes.length; i++) {
            _newValue[j++] = _xBytes[i];
        }

        for (i = 0; i < _yBytes.length; i++) {
            _newValue[j++] = _yBytes[i];
        }

        return string(_newValue);
    }
}
