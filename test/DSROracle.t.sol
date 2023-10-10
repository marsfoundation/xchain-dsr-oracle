// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PotMock } from "./mocks/PotMock.sol";

import { DSROracle } from "../src/DSROracle.sol";

contract DSROracleTest is Test {

    uint256 constant DSR_FIVE_PCT_APY = 1.000000001547125957863212448e27;
    uint256 constant DSR_FIVE_PCT_APR = 0.048790164207174267760128000e27;

    PotMock   pot;
    DSROracle oracle;

    function setUp() public {
        pot = new PotMock();
        oracle = new DSROracle(address(pot));
    }

    function test_storage_defaults() public {
        assertEq(oracle.getDSR(), 1e27);
        assertEq(oracle.getChi(), 1e27);
        assertEq(oracle.getRho(), block.timestamp);
    }

    function test_apr() public {
        assertEq(oracle.getAPR(), 0);

        pot.setDSR(DSR_FIVE_PCT_APY);

        assertEq(oracle.getAPR(), 0);

        oracle.refresh();

        assertEq(oracle.getAPR(), DSR_FIVE_PCT_APR);
    }

    function test_getConversionRate() public {
        assertEq(oracle.getConversionRate(), 1e27);
        assertEq(oracle.getConversionRate(block.timestamp + 365 days), 1e27);

        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();

        assertEq(oracle.getConversionRate(), 1.03e27);
        assertEq(oracle.getConversionRate(block.timestamp + 365 days), 1.081499999999999999959902249e27);
    }

    function test_gas_getConversionRate() public {
        vm.pauseGasMetering();
        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRate(block.timestamp + 365 days);
    }

    function test_getConversionRate_pastRevert() public {
        vm.expectRevert();
        oracle.getConversionRate(block.timestamp - 365 days);
    }

    function test_getConversionRateBinomialApprox() public {
        assertEq(oracle.getConversionRateBinomialApprox(), 1e27);
        assertEq(oracle.getConversionRateBinomialApprox(block.timestamp + 365 days), 1e27);

        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();

        assertEq(oracle.getConversionRateBinomialApprox(), 1.03e27);
        assertEq(oracle.getConversionRateBinomialApprox(block.timestamp + 365 days), 1.081495968383924399665215760e27);
    }

    function test_gas_getConversionRateBinomialApprox() public {
        vm.pauseGasMetering();
        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateBinomialApprox(block.timestamp + 365 days);
    }

    function test_getConversionRateBinomialApprox_pastRevert() public {
        vm.expectRevert();
        oracle.getConversionRateBinomialApprox(block.timestamp - 365 days);
    }

    function test_getConversionRateLinearApprox() public {
        assertEq(oracle.getConversionRateLinearApprox(), 1e27);
        assertEq(oracle.getConversionRateLinearApprox(block.timestamp + 365 days), 1e27);

        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();

        assertEq(oracle.getConversionRateLinearApprox(), 1.03e27);
        assertEq(oracle.getConversionRateLinearApprox(block.timestamp + 365 days), 1.078790164207174267760128000e27);
    }

    function test_gas_getConversionRateLinearApprox() public {
        vm.pauseGasMetering();
        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateLinearApprox(block.timestamp + 365 days);
    }

    function test_getConversionRateLinearApprox_pastRevert() public {
        vm.expectRevert();
        oracle.getConversionRateLinearApprox(block.timestamp - 365 days);
    }

    function test_binomialAccuracyLongDuration() public {
        pot.setDSR(DSR_FIVE_PCT_APY);
        pot.setChi(1.03e27);
        oracle.refresh();

        // Even after a year the binomial is accurate to within 0.001%
        assertApproxEqRel(
            oracle.getConversionRate(block.timestamp + 365 days),
            oracle.getConversionRateBinomialApprox(block.timestamp + 365 days),
            0.00001e18
        );
    }

    function test_getConversionRateFuzz(uint256 rate, uint256 duration) public {
        rate = bound(rate, 0, 1e27);            // Bound by 0-100% APR
        duration = bound(duration, 0, 1 days);  // Bound by 1 day

        pot.setDSR(rate / 365 days + 1e27);
        oracle.refresh();

        skip(duration);

        // Error bounds
        uint256 exact = oracle.getConversionRate();
        assertApproxEqRel(exact, oracle.getConversionRateBinomialApprox(), 0.00000000001e18, "binomial out of range");
        assertApproxEqRel(exact, oracle.getConversionRateLinearApprox(), 0.00005e18, "linear out of range");

        // Binomial and then linear should always underestimate
        assertGe(exact, oracle.getConversionRateBinomialApprox());
        assertGe(oracle.getConversionRateBinomialApprox(), oracle.getConversionRateLinearApprox());
    }

}
