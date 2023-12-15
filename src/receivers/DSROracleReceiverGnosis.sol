// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { GnosisReceiver } from 'xchain-helpers/GnosisReceiver.sol';

import { IDSRAuthOracle, IDSROracle } from '../interfaces/IDSRAuthOracle.sol';

contract DSROracleReceiverGnosis is GnosisReceiver {

    IDSRAuthOracle public oracle;

    constructor(
        address _l2CrossDomain,
        uint256 _chainId,
        address _l1Authority,
        IDSRAuthOracle _oracle
    ) GnosisReceiver(_l2CrossDomain, _chainId, _l1Authority) {
        oracle = _oracle;
    }

    function setPotData(IDSROracle.PotData calldata data) external onlyCrossChainMessage {
        oracle.setPotData(data);
    }

}
