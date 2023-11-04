// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { BridgedDomain, Domain } from "xchain-helpers/testing/BridgedDomain.sol";

import { DSROracle, IPot } from "../src/DSROracle.sol";
import { DSROracleChainlinkAdapter } from "../src/adapters/DSROracleChainlinkAdapter.sol";

interface IPotDripLike {
    function drip() external;
}

interface IAaveOracleLike {
    function getAssetPrice(address _asset) external view returns (uint256);
    function setAssetSources(address[] calldata _assets, address[] calldata _sources) external;
}

contract DSROracleIntegrationTest is Test {

    address pot;
    IAaveOracleLike aaveOracle;
    address sdai;
    address admin;

    DSROracle oracle;
    DSROracleChainlinkAdapter adapter;

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18_421_823);
        
        pot = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
        aaveOracle = IAaveOracleLike(0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9);
        sdai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
        admin = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

        assertEq(IPot(pot).dsr(), 1.000000001547125957863212448e27);
        assertEq(IPot(pot).chi(), 1.039942074479136064327544607e27);
        assertEq(IPot(pot).rho(), 1698170603);
        assertLt(IPot(pot).rho(), block.timestamp);

        oracle = new DSROracle(address(pot));
        adapter = new DSROracleChainlinkAdapter(oracle);
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

    function test_replace_sdai_oracle() public {
        assertEq(aaveOracle.getAssetPrice(sdai), 1.03988177e8);

        address[] memory assets = new address[](1);
        assets[0] = sdai;
        address[] memory sources = new address[](1);
        sources[0] = address(adapter);

        vm.prank(admin);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        assertEq(aaveOracle.getAssetPrice(sdai), 1.03994292e8);
        assertEq(aaveOracle.getAssetPrice(sdai), oracle.getConversionRateBinomialApprox() / 1e19);
    }

}
