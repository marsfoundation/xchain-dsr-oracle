// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IDSROracle } from "../interfaces/IDSROracle.sol";

/**
 * @title  DSROracleChainlinkAdapter
 * @notice A thin adapter which uses a binomial approximation to get an up-to-date DSR conversion price.
 */
contract DSROracleChainlinkAdapter {

    IDSROracle public immutable dsrOracle;

    constructor(IDSROracle _dsrOracle) {
        dsrOracle = _dsrOracle;
    }

    function latestAnswer() external view returns (int256) {
        // 27 decimals - 8 decimals = 1e19
        // Not checking the int256 cast as it will always be less than the max
        return int256(dsrOracle.getConversionRateBinomialApprox() / 1e19);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

}
