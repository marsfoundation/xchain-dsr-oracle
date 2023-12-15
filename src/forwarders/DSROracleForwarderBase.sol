// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSRAuthOracle, IDSROracle } from '../interfaces/IDSRAuthOracle.sol';
import { IPot }                       from '../interfaces/IPot.sol';

/**
 * @title  DSROracleForwarderBase
 * @notice Base contract for relaying pot data messages cross-chain.
 */
abstract contract DSROracleForwarderBase {

    IPot    public immutable pot;
    address public immutable l2Oracle;

    constructor(address _pot, address _l2Oracle) {
        pot      = IPot(_pot);
        l2Oracle = _l2Oracle;
    }

    function _packMessage() internal view returns (bytes memory) {
        return abi.encodeCall(
            IDSRAuthOracle.setPotData,
            (IDSROracle.PotData({
                dsr: uint96(pot.dsr()),
                chi: uint120(pot.chi()),
                rho: uint40(pot.rho())
            }))
        );
    }

}
