// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { DSRAuthOracle, IDSROracle } from "../src/DSRAuthOracle.sol";

contract DSRAuthOracleTest is Test {

    event SetPotData(IDSROracle.PotData nextData);

    uint256 constant FIVE_PCT_APY_DSR        = 1.000000001547125957863212448e27;
    uint256 constant ONE_HUNDRED_PCT_APY_DSR = 1.00000002197955315123915302e27;

    DSRAuthOracle oracle;

    function setUp() public {
        // To get some reasonable timestamps that are not 1
        skip(1 * (365 days));

        oracle = new DSRAuthOracle();

        // Feed initial data and set limits
        oracle.grantRole(oracle.DATA_PROVIDER_ROLE(), address(this));
        oracle.setMaxDSR(ONE_HUNDRED_PCT_APY_DSR);
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27),
            rho: uint40(block.timestamp)
        }));

        skip(1 * (365 days));
    }

    function test_setPotData_rho_decreasing() public {
        uint256 rho = oracle.getRho();
        vm.expectRevert("DSRAuthOracle/invalid-rho");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1.03e27),
            rho: uint40(rho - 1)
        }));
    }

    function test_setPotData_rho_in_future() public {
        vm.expectRevert("DSRAuthOracle/invalid-rho");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp + 1)
        }));
    }

    function test_setPotData_dsr_below_zero() public {
        vm.expectRevert("DSRAuthOracle/invalid-dsr");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(1e27 - 1),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_dsr_above_100pct() public {
        vm.expectRevert("DSRAuthOracle/invalid-dsr");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(ONE_HUNDRED_PCT_APY_DSR + 1),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_chi_decreasing() public {
        vm.expectRevert("DSRAuthOracle/invalid-chi");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1e27 - 1),
            rho: uint40(block.timestamp)
        }));
    }

    function test_setPotData_chi_growth_too_fast() public {
        vm.expectRevert("DSRAuthOracle/invalid-chi");
        oracle.setPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(10e27),      // 10x return in 1 year is impossible below 100% APY
            rho: uint40(block.timestamp)
        }));
    }

}
