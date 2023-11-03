// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSROracle } from './interfaces/IDSROracle.sol';

/**
 * @title  DSROracleBase
 * @notice Base functionality for all DSR oracles.
 */
abstract contract DSROracleBase is IDSROracle {

    uint256 private constant RAY = 1e27;

    uint256 private constant MIN_DSR = RAY;                                    // 0%
    uint256 private constant MAX_DSR = 1.00000002197955315123915302e27;        // 100%

    IDSROracle.PotData internal _data;

    function _setPotData(IDSROracle.PotData memory nextData) internal {
        IDSROracle.PotData memory previousData = _data;
        if (_data.rho == 0) {
            // This is a first update
            _data = nextData;
            return;
        }

        // Perform sanity checks to minimize damage in the event of a bridge attack

        // Enforce non-decreasing values of rho in case of message reordering
        // The same timestamp is allowed as the other values will only change upon increasing rho
        require(nextData.rho >= previousData.rho, 'DSROracleBase/invalid-rho');

        // Timestamp must be in the past
        require(nextData.rho <= block.timestamp, 'DSROracleBase/invalid-rho');

        // DSR sanity bounds
        require(nextData.dsr >= MIN_DSR, 'DSROracleBase/invalid-dsr');
        require(nextData.dsr <= MAX_DSR, 'DSROracleBase/invalid-dsr');

        // chi must be non-decreasing
        require(nextData.chi >= previousData.chi, 'DSROracleBase/invalid-chi');

        // Accumulation cannot be larger than the time elapsed at the MAX_DSR
        uint256 chiMax = _rpow(MAX_DSR, nextData.rho - previousData.rho) * previousData.chi / RAY;
        require(nextData.chi <= chiMax, 'DSROracleBase/invalid-chi');

        _data = nextData;
    }

    function getPotData() external view returns (IDSROracle.PotData memory) {
        return _data;
    }

    function getDSR() external view returns (uint256) {
        return _data.dsr;
    }

    function getChi() external view returns (uint256) {
        return _data.chi;
    }

    function getRho() external view returns (uint256) {
        return _data.rho;
    }

    function getAPR() external view returns (uint256) {
        unchecked {
            return (_data.dsr - RAY) * 365 days;
        }
    }

    function getConversionRate() external view returns (uint256) {
        return getConversionRate(block.timestamp);
    }

    function getConversionRate(uint256 timestamp) public view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        return (timestamp > rho) ? _rpow(d.dsr, timestamp - rho) * d.chi / RAY : d.chi;
    }

    function getConversionRateBinomialApprox() external view returns (uint256) {
        return getConversionRateBinomialApprox(block.timestamp);
    }

    // Copied and slightly modified from https://github.com/aave/aave-v3-core/blob/42103522764546a4eeb856b741214fa5532be52a/contracts/protocol/libraries/math/MathUtils.sol#L50
    function getConversionRateBinomialApprox(uint256 timestamp) public view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 exp = timestamp - d.rho;
        uint256 rate;
        unchecked {
            rate = d.dsr - RAY;
        }

        if (exp == 0) {
            return d.chi;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo = rate * rate / RAY;
            basePowerThree = basePowerTwo * rate / RAY;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return d.chi * (RAY + (rate * exp) + secondTerm + thirdTerm) / RAY;
    }

    function getConversionRateLinearApprox() external view returns (uint256) {
        return getConversionRateLinearApprox(block.timestamp);
    }

    function getConversionRateLinearApprox(uint256 timestamp) public view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp > rho) {
            uint256 rate;
            unchecked {
                rate = d.dsr - RAY;
            }
            return rate * (timestamp - rho) + d.chi;
        } else {
            return d.chi;
        }
    }

    // Copied from https://github.com/makerdao/sdai/blob/e6f8cfa1d638b1ef1c6187a1d18f73b21d2754a2/src/SavingsDai.sol#L118
    function _rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := RAY} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := RAY } default { z := x }
                let half := div(RAY, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, RAY)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, RAY)
                    }
                }
            }
        }
    }

}
