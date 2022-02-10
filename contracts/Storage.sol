pragma solidity 0.6.12;

contract Storage {

    mapping (string => string) private _store;

    function addData(string memory key, string memory value) public {
        require(bytes(_store[key]).length == 0);
        _store[key] = value;
    }

    function removeData(string memory key) public returns (string memory) {
        require(bytes(_store[key]).length != 0);
        string memory prev = _store[key];
        delete _store[key];
        return prev;
    }

    function changeData(string memory key, string memory newValue) public {
        require(bytes(_store[key]).length != 0);
        _store[key] = newValue;
    }
}