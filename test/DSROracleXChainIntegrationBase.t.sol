// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";

import { Bridge }                from "xchain-helpers/testing/Bridge.sol";
import { Domain, DomainHelpers } from "xchain-helpers/testing/Domain.sol";

import { DSRAuthOracle  }                  from "../src/DSRAuthOracle.sol";
import { DSROracleForwarderBase  }         from "../src/forwarders/DSROracleForwarderBase.sol";
import { DSRBalancerRateProviderAdapter  } from "../src/adapters/DSRBalancerRateProviderAdapter.sol";
import { IDSROracle }                      from "../src/interfaces/IDSROracle.sol";
import { IPot }                            from "../src/interfaces/IPot.sol";

interface IPotDripLike {
    function drip() external;
}

abstract contract DSROracleXChainIntegrationBaseTest is Test {

    using DomainHelpers for *;

    uint256 constant CURR_DSR = 1.000000001547125957863212448e27;
    uint256 constant CURR_CHI = 1.039942074479136064327544607e27;
    uint256 constant CURR_RHO = 1698170603;

    Domain mainnet;
    Domain remote;
    Bridge bridge;

    address pot  = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address sdai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

    DSROracleForwarderBase forwarder;

    DSRAuthOracle oracle;

    // Test various adapters
    DSRBalancerRateProviderAdapter balancerAdapter;

    function setUp() public {
        mainnet = getChain("mainnet").createSelectFork(18421823);  // Oct 24, 2023

        assertEq(IPot(pot).dsr(), CURR_DSR);
        assertEq(IPot(pot).chi(), CURR_CHI);
        assertEq(IPot(pot).rho(), CURR_RHO);

        setupDomain();

        remote.selectFork();

        balancerAdapter = new DSRBalancerRateProviderAdapter(oracle);
    }

    function setupDomain() internal virtual;
    function doRefresh() internal virtual;
    function relayMessagesAcrossBridge() internal virtual;

    function test_xchain_relay() public {
        remote.selectFork();

        assertEq(oracle.getDSR(), 0);
        assertEq(oracle.getChi(), 0);
        assertEq(oracle.getRho(), 0);

        mainnet.selectFork();

        // Anchor the time to the RHO so we can check the hard coded value
        vm.warp(CURR_RHO + 30 days);

        uint256 sdaiConversionRate = IERC4626(sdai).convertToAssets(1e18);
        assertEq(sdaiConversionRate, 1.044120771690352453e18);

        IDSROracle.PotData memory data = forwarder.getLastSeenPotData();
        assertEq(data.dsr,                   0);
        assertEq(data.chi,                   0);
        assertEq(data.rho,                   0);
        assertEq(forwarder.getLastSeenDSR(), 0);
        assertEq(forwarder.getLastSeenChi(), 0);
        assertEq(forwarder.getLastSeenRho(), 0);

        doRefresh();

        data = forwarder.getLastSeenPotData();
        assertEq(data.dsr,                   CURR_DSR);
        assertEq(data.chi,                   CURR_CHI);
        assertEq(data.rho,                   CURR_RHO);
        assertEq(forwarder.getLastSeenDSR(), CURR_DSR);
        assertEq(forwarder.getLastSeenChi(), CURR_CHI);
        assertEq(forwarder.getLastSeenRho(), CURR_RHO);

        relayMessagesAcrossBridge();
        vm.warp(CURR_RHO + 30 days);

        assertEq(oracle.getDSR(), CURR_DSR);
        assertEq(oracle.getChi(), CURR_CHI);
        assertEq(oracle.getRho(), CURR_RHO);

        assertEq(balancerAdapter.getRate(), 1.044120769556671376e18);
        assertApproxEqAbs(balancerAdapter.getRate(), sdaiConversionRate, 1e10);
    }

}
