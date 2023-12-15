// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSROracle } from './interfaces/IDSROracle.sol';

/**
 * @title  DSROracleBase
 * @notice Base functionality for all DSR oracles.
 */
abstract contract DSROracleBase is IDSROracle {

    uint256 private constant RAY = 1e27;

    IDSROracle.PotData internal _data;

    function _setPotData(IDSROracle.PotData memory nextData) internal {
        _data = nextData;

        emit SetPotData(nextData);
    }

    function getPotData() external override view returns (IDSROracle.PotData memory) {
        return _data;
    }

    function getDSR() external override view returns (uint256) {
        return _data.dsr;
    }

    function getChi() external override view returns (uint256) {
        return _data.chi;
    }

    function getRho() external override view returns (uint256) {
        return _data.rho;
    }

    function getAPR() external override view returns (uint256) {
        unchecked {
            return (_data.dsr - RAY) * 365 days;
        }
    }

    function getConversionRate() external override view returns (uint256) {
        return getConversionRate(block.timestamp);
    }

    function getConversionRate(uint256 timestamp) public override view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp == rho) return d.chi;
        require(timestamp >= rho, "DSROracleBase/invalid-timestamp");

        return (timestamp > rho) ? _rpow(d.dsr, timestamp - rho) * uint256(d.chi) / RAY : d.chi;
    }

    function getConversionRateBinomialApprox() external override view returns (uint256) {
        return getConversionRateBinomialApprox(block.timestamp);
    }

    // Copied and slightly modified from https://github.com/aave/aave-v3-core/blob/42103522764546a4eeb856b741214fa5532be52a/contracts/protocol/libraries/math/MathUtils.sol#L50
    function getConversionRateBinomialApprox(uint256 timestamp) public override view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp == rho) return d.chi;
        require(timestamp >= rho, "DSROracleBase/invalid-timestamp");
        
        uint256 exp;
        uint256 rate;
        unchecked {
            exp = timestamp - rho;
            rate = d.dsr - RAY;
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

    function getConversionRateLinearApprox() external override view returns (uint256) {
        return getConversionRateLinearApprox(block.timestamp);
    }

    function getConversionRateLinearApprox(uint256 timestamp) public override view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp == rho) return d.chi;
        require(timestamp >= rho, "DSROracleBase/invalid-timestamp");
        
        uint256 duration;
        uint256 rate;
        unchecked {
            duration = timestamp - rho;
            rate = uint256(d.dsr) - RAY;
        }
        return (rate * duration + RAY) * uint256(d.chi) / RAY;
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
