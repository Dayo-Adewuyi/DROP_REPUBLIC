// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";

contract AdminFacet is IERC173 {
    AppStorage s;

    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    function pause() external {
        LibDiamond.enforceIsContractOwner();
        s.isPaused = !s.isPaused;
    }

    function isPaused() public view returns(bool){
        return s.isPaused;
    }
}
