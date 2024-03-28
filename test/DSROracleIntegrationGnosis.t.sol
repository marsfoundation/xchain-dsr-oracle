// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { GnosisDomain } from "xchain-helpers/testing/GnosisDomain.sol";

import { DSROracleForwarderGnosis } from "src/forwarders/DSROracleForwarderGnosis.sol";
import { DSROracleReceiverGnosis }  from "src/receivers/DSROracleReceiverGnosis.sol";

import "./DSROracleXChainIntegrationBase.t.sol";

contract DSROracleIntegrationGnosisTest is DSROracleXChainIntegrationBaseTest {

    address constant AMB = 0x75Df5AF045d91108662D8080fD1FEFAd6aA0bb59;

    DSROracleForwarderGnosis forwarder;
    DSROracleReceiverGnosis  receiver;

    function setupDomain() internal override {
        remote = new GnosisDomain(getChain('gnosis_chain'), mainnet);

        mainnet.selectFork();

        forwarder = new DSROracleForwarderGnosis(address(pot), computeCreateAddress(address(this), 5));

        remote.selectFork();

        oracle   = new DSRAuthOracle();
        receiver = new DSROracleReceiverGnosis(AMB, 1, address(forwarder), oracle);

        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(receiver));
    }

    function doRefresh() internal override {
        forwarder.refresh(500_000);
    }

}
