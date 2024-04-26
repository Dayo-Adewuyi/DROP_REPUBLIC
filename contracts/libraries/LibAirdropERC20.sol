// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AppStorage} from "./LibAppStorage.sol";
import {IERC20, IERC20Errors} from "../interfaces/IERC20.sol";

library LibAirdropERC20 {

function claimDrop(
    AppStorage storage s,
    address _to,
    bytes32[] calldata proof,
    uint256 _dropId,
    uint256 _amount
) internal {
    require(!s.airDrops[_dropId].claimed[_to], "Tokens already claimed");
    require(_to != address(0), "Invalid recipient address");

    bytes32 merkleRoot = s.airDrops[_dropId].merkleRoot;
    require(
        verifyProof(merkleRoot, keccak256(abi.encodePacked(_to, _amount)), proof),
        "Invalid proof"
    );

    s.airDrops[_dropId].claimed[_to] = true;
    address token = s.airDrops[_dropId].token;
    address source = s.airDrops[_dropId].source;
    IERC20(token).transferFrom(source, _to, _amount);
}

function verifyProof(
    bytes32 root,
    bytes32 leaf,
    bytes32[] calldata proof
) internal pure returns (bool) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];
        if (computedHash < proofElement) {
            computedHash = _efficientKeccak256(computedHash, proofElement);
        } else {
            computedHash = _efficientKeccak256(proofElement, computedHash);
        }
    }
    return computedHash == root;
}
function batchTransfer(
    AppStorage storage s,
    address _token,
    address _from,
    address[] calldata _recipients,
    uint256[] calldata _amount
) internal {
    require(_from != address(0), "Invalid sender");
    require(
        _recipients.length == _amount.length,
        "Recipient and amount mismatch"
    );

    uint256 totalAmount = getTotalAmount(_amount);

    uint256 balance = IERC20(_token).balanceOf(_from);
    if (balance < totalAmount) {
        revert IERC20Errors.ERC20InsufficientBalance(
            _from,
            balance,
            totalAmount
        );
    }

    uint256 batchSize = s.batchSize;

    for (uint256 i = 0; i < _recipients.length; i += batchSize) {
        uint256 end = (i + batchSize) > _recipients.length
            ? _recipients.length
            : (i + batchSize);
        _transferBatch(_token, _from, _recipients, _amount, i, end);
    }
}

function _transferBatch(
    address _token,
    address _from,
    address[] memory _recipients,
    uint256[] memory _amount,
    uint256 _start,
    uint256 _end
) private {
    for (uint256 i = _start; i < _end; i++) {
        require(_recipients[i] != address(0), "Invalid receiver");
        bool success = IERC20(_token).transferFrom(_from, _recipients[i], _amount[i]);
        require(success, "Transfer failed");
    }
}

function getTotalAmount(
    uint256[] calldata _amount
) internal pure returns (uint256) {
    uint256 totalAmount;
    for (uint256 i = 0; i < _amount.length; i++) {
        totalAmount += _amount[i];
    }
    return totalAmount;
}

  function _efficientKeccak256(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

}
