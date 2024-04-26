// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {LibAirdropERC20} from "../libraries/LibAirdropERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IERC20, IERC20Errors} from "../interfaces/IERC20.sol";

contract AirdropRepublic {
    AppStorage s;

    modifier NotPaused() {
        require(!s.isPaused, "Facet Paused");
        _;
    }

    function createAirdrop(
        address _token,
        address _source,
        bytes32 _merkleRoot
    ) external NotPaused {
        require(_source != address(0), "Invalid source address");
        require(_token != address(0), "Invalid token address");
        require(_merkleRoot.length > 0, "Invalid Merkle root");

        s.dropCount++;
        uint256 dropId = s.dropCount;

        s.airDrops[dropId].dropId = dropId;
        s.airDrops[dropId].source = _source;
        s.airDrops[dropId].token = _token;
        s.airDrops[dropId].merkleRoot = _merkleRoot; 
        emit AirdropCreated(s.dropCount, _source, _token, _merkleRoot);
    }

    function claimToken(bytes32[] calldata proof,
    uint256 _dropId,
    uint256 _amount) external NotPaused {
        require(proof.length > 0, "Invalid Proof");
        LibAirdropERC20.claimDrop( s,
    msg.sender,
    proof,
    _dropId,
     _amount);
    }
    function batchTransfer(
        address token,
        address[] calldata _to,
        uint256[] calldata _amount
    ) external NotPaused {
        require(
            _to.length == _amount.length,
            "Recipient and amount arrays mismatch"
        );
        uint totalAmount = LibAirdropERC20.getTotalAmount(_amount);
        uint allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= totalAmount, "Insufficient allowance");

        LibAirdropERC20.batchTransfer(s, token, msg.sender, _to, _amount);
        emit TokensTransferred(token, msg.sender, _to, _amount);
    }

function getDropIdByTokenAndMerkleRoot(address _token, bytes32 _merkleRoot) external view NotPaused returns (uint256) {
   
    for (uint256 i = 0; i < s.dropCount; i++) {
        if (s.airDrops[i].token == _token && s.airDrops[i].merkleRoot == _merkleRoot) {
            return s.airDrops[i].dropId;
        }
    }
    revert("Airdrop not found");
}

    // Events for transparency
    event AirdropCreated(
        uint256 indexed dropId,
        address indexed source,
        address indexed token,
        bytes32 merkleRoot
    );
    event TokensTransferred(
        address indexed token,
        address indexed sender,
        address[] recipients,
        uint256[] amounts
    );
}
