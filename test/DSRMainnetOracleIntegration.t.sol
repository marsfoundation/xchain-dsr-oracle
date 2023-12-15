// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { BridgedDomain, Domain } from "xchain-helpers/testing/BridgedDomain.sol";

import { DSRMainnetOracle, IPot } from "../src/DSRMainnetOracle.sol";

interface IPotDripLike {
    function drip() external;
}

contract DSRMainnetOracleIntegrationTest is Test {

    address pot = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    DSRMainnetOracle oracle;

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18_421_823);

        assertEq(IPot(pot).dsr(), 1.000000001547125957863212448e27);
        assertEq(IPot(pot).chi(), 1.039942074479136064327544607e27);
        assertEq(IPot(pot).rho(), 1698170603);

        oracle = new DSRMainnetOracle(address(pot));
    }

    function test_drip_update() public {
        assertEq(oracle.getDSR(), 1.000000001547125957863212448e27);
        assertEq(oracle.getChi(), 1.039942074479136064327544607e27);
        assertEq(oracle.getRho(), 1698170603);

        IPotDripLike(pot).drip();

        assertEq(IPot(pot).dsr(), 1.000000001547125957863212448e27);
        assertGt(IPot(pot).chi(), 1.039942074479136064327544607e27);
        assertEq(IPot(pot).rho(), block.timestamp);
        
        oracle.refresh();

        assertEq(oracle.getDSR(), 1.000000001547125957863212448e27);
        assertEq(oracle.getChi(), IPot(pot).chi());
        assertEq(oracle.getRho(), block.timestamp);
    }

}
