// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { ArbitrumReceiver } from 'xchain-helpers/ArbitrumReceiver.sol';

import { IDSRAuthOracle, IDSROracle } from '../interfaces/IDSRAuthOracle.sol';

contract DSROracleReceiverArbitrum is ArbitrumReceiver {

    IDSRAuthOracle public oracle;

    constructor(
        address _l1Authority,
        IDSRAuthOracle _oracle
    ) ArbitrumReceiver(_l1Authority) {
        oracle = _oracle;
    }

    function setPotData(IDSROracle.PotData calldata data) external onlyCrossChainMessage {
        oracle.setPotData(data);
    }

}
