// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { BridgedDomain, Domain } from "xchain-helpers/testing/BridgedDomain.sol";

import { DSRAuthOracle  } from "../src/DSRAuthOracle.sol";
import { IPot }           from "../src/interfaces/IPot.sol";

interface IPotDripLike {
    function drip() external;
}

abstract contract DSROracleXChainIntegrationBaseTest is Test {

    Domain mainnet;
    BridgedDomain remote;

    address pot = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    DSRAuthOracle oracle;

    function setUp() public {
        mainnet = new Domain(getChain("mainnet"));
        mainnet.rollFork(18_421_823);
        mainnet.selectFork();

        assertEq(IPot(pot).dsr(), 1.000000001547125957863212448e27);
        assertEq(IPot(pot).chi(), 1.039942074479136064327544607e27);
        assertEq(IPot(pot).rho(), 1698170603);

        setupDomain();
    }

    function setupDomain() internal virtual;
    function doRefresh() internal virtual;

    function test_xchain_relay() public {
        remote.selectFork();

        assertEq(oracle.getDSR(), 0);
        assertEq(oracle.getChi(), 0);
        assertEq(oracle.getRho(), 0);

        mainnet.selectFork();

        doRefresh();

        remote.relayFromHost(true);

        assertEq(oracle.getDSR(), 1.000000001547125957863212448e27);
        assertEq(oracle.getChi(), 1.039942074479136064327544607e27);
        assertEq(oracle.getRho(), 1698170603);
    }

}
