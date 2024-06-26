// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { OptimismForwarder } from 'xchain-helpers/forwarders/OptimismForwarder.sol';

import { DSROracleForwarderBase } from './DSROracleForwarderBase.sol';

contract DSROracleForwarderBaseChain is DSROracleForwarderBase {

    constructor(address _pot, address _l2Oracle) DSROracleForwarderBase(_pot, _l2Oracle) {
        // Intentionally left blank
    }

    function refresh(uint256 gasLimit) public {
        OptimismForwarder.sendMessageL1toL2(
            OptimismForwarder.L1_CROSS_DOMAIN_BASE,
            address(l2Oracle),
            _packMessage(),
            gasLimit
        );
    }

}
