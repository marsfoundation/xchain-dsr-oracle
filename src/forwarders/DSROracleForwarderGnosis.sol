// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { XChainForwarders } from 'xchain-helpers/XChainForwarders.sol';
import { DSROracleForwarderBase } from './DSROracleForwarderBase.sol';

contract DSROracleForwarderGnosis is DSROracleForwarderBase {

    constructor(address _pot, address _l2Oracle) DSROracleForwarderBase(_pot, _l2Oracle) {
        // Intentionally left blank
    }

    function refresh(uint256 gasLimit) public {
        XChainForwarders.sendMessageGnosis(
            address(l2Oracle),
            _packMessage(),
            gasLimit
        );
    }

}
