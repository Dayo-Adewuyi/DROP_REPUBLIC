
//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

struct AirDrop{
    uint256 dropId;
    address source;
    address token;
    bytes32 merkleRoot;
    mapping(address => bool) claimed;
}

struct AppStorage {
uint256 dropCount;
uint256 batchSize;
mapping(uint => AirDrop ) airDrops;
bool isPaused;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}