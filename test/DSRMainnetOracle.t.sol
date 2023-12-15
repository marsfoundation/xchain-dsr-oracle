// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PotMock } from "./mocks/PotMock.sol";

import { DSRMainnetOracle, IDSROracle } from "../src/DSRMainnetOracle.sol";

contract DSRMainnetOracleTest is Test {

    event SetPotData(IDSROracle.PotData nextData);

    uint256 constant FIVE_PCT_APY_DSR        = 1.000000001547125957863212448e27;
    uint256 constant FIVE_PCT_APY_APR        = 0.048790164207174267760128000e27;
    uint256 constant ONE_HUNDRED_PCT_APY_DSR = 1.00000002197955315123915302e27;

    uint256 ONE_YEAR;

    PotMock          pot;
    DSRMainnetOracle oracle;

    function setUp() public {
        // To get some reasonable timestamps that are not 1
        skip(1 * (365 days));

        pot = new PotMock();

        skip(1 * (365 days));

        ONE_YEAR = block.timestamp + 365 days;

        oracle = new DSRMainnetOracle(address(pot));
    }

    function test_storage_defaults() public {
        assertEq(oracle.getDSR(), pot.dsr());
        assertEq(oracle.getChi(), pot.chi());
        assertEq(oracle.getRho(), pot.rho());
    }

    function test_refresh() public {
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);

        vm.expectEmit();
        emit SetPotData(IDSROracle.PotData({
            dsr: uint96(FIVE_PCT_APY_DSR),
            chi: uint120(1.03e27),
            rho: uint40(block.timestamp)
        }));
        oracle.refresh();

        assertEq(oracle.getDSR(), FIVE_PCT_APY_DSR);
        assertEq(oracle.getChi(), 1.03e27);
        assertEq(oracle.getRho(), block.timestamp);
    }

    function test_apr() public {
        assertEq(oracle.getAPR(), 0);

        pot.setDSR(FIVE_PCT_APY_DSR);

        assertEq(oracle.getAPR(), 0);

        oracle.refresh();

        assertEq(oracle.getAPR(), FIVE_PCT_APY_APR);
    }

    function test_getConversionRate() public {
        assertEq(oracle.getConversionRate(),         1e27);
        assertEq(oracle.getConversionRate(ONE_YEAR), 1e27);

        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();

        assertEq(oracle.getConversionRate(),         1.03e27);
        assertEq(oracle.getConversionRate(ONE_YEAR), 1.081499999999999999959902249e27);   // 5% interest on 1.03 value = 1.0815
    }

    function test_gas_getConversionRate_1hour() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRate(block.timestamp + 1 hours);
    }

    function test_gas_getConversionRate_1year() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRate(ONE_YEAR);
    }

    function test_getConversionRate_pastRevert() public {
        uint256 rho = oracle.getRho();
        vm.expectRevert("DSROracleBase/invalid-timestamp");
        oracle.getConversionRate(rho - 1);

        oracle.getConversionRate(rho);
    }

    function test_getConversionRateBinomialApprox() public {
        assertEq(oracle.getConversionRateBinomialApprox(),         1e27);
        assertEq(oracle.getConversionRateBinomialApprox(ONE_YEAR), 1e27);

        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();

        assertEq(oracle.getConversionRateBinomialApprox(),         1.03e27);
        assertEq(oracle.getConversionRateBinomialApprox(ONE_YEAR), 1.081495968383924399665215760e27);   // 5% interest on 1.03 value = 1.0815
    }

    function test_gas_getConversionRateBinomialApprox_1hour() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateBinomialApprox(block.timestamp + 1 hours);
    }

    function test_gas_getConversionRateBinomialApprox_1year() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateBinomialApprox(ONE_YEAR);
    }

    function test_getConversionRateBinomialApprox_pastRevert() public {
        uint256 rho = oracle.getRho();
        vm.expectRevert("DSROracleBase/invalid-timestamp");
        oracle.getConversionRateBinomialApprox(rho - 1);

        oracle.getConversionRateBinomialApprox(rho);
    }

    function test_getConversionRateLinearApprox() public {
        assertEq(oracle.getConversionRateLinearApprox(),         1e27);
        assertEq(oracle.getConversionRateLinearApprox(ONE_YEAR), 1e27);

        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();

        assertEq(oracle.getConversionRateLinearApprox(),         1.03e27);
        assertEq(oracle.getConversionRateLinearApprox(ONE_YEAR), 1.080253869133389495792931840e27);   // 5% interest on 1.03 value = 1.0815, but linear approx is 1.0802
    }

    function test_gas_getConversionRateLinearApprox_1hour() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateLinearApprox(block.timestamp + 1 hours);
    }

    function test_gas_getConversionRateLinearApprox_1year() public {
        vm.pauseGasMetering();
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();
        vm.resumeGasMetering();

        oracle.getConversionRateLinearApprox(ONE_YEAR);
    }

    function test_getConversionRateLinearApprox_pastRevert() public {
        uint256 rho = oracle.getRho();
        vm.expectRevert("DSROracleBase/invalid-timestamp");
        oracle.getConversionRateLinearApprox(rho - 1);

        oracle.getConversionRateLinearApprox(rho);
    }

    function test_binomialAccuracyLongDuration() public {
        pot.setDSR(FIVE_PCT_APY_DSR);
        pot.setChi(1.03e27);
        pot.setRho(block.timestamp);
        oracle.refresh();

        // Even after a year the binomial is accurate to within 0.001%
        assertApproxEqRel(
            oracle.getConversionRate(ONE_YEAR),
            oracle.getConversionRateBinomialApprox(ONE_YEAR),
            0.00001e18
        );
    }

    function test_getConversionRateFuzz(uint256 rate, uint256 duration) public {
        rate     = bound(rate,     0, 0.5e27);  // Bound by 0-50% APR
        duration = bound(duration, 0, 1 days);  // Bound by 1 day

        pot.setDSR(rate / 365 days + 1e27);
        pot.setRho(block.timestamp);
        oracle.refresh();

        skip(duration);

        uint256 exact    = oracle.getConversionRate();
        uint256 binomial = oracle.getConversionRateBinomialApprox();
        uint256 linear   = oracle.getConversionRateLinearApprox();

        // Error bounds
        assertApproxEqRel(exact, binomial, 0.00000000001e18, "binomial out of range");
        assertApproxEqRel(exact, linear,   0.00005e18,       "linear out of range");

        // Binomial and then linear should always underestimate
        assertGe(exact,    binomial);
        assertGe(binomial, linear);
    }

}
