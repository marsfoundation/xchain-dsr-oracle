// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IDSROracle } from "../interfaces/IDSROracle.sol";

interface IRateProvider {
    function getRate() external view returns (uint256);
}

/**
 * @title  DSRBalancerRateProviderAdapter
 * @notice A thin adapter which uses a binomial approximation to get an up-to-date DSR conversion price.
 */
contract DSRBalancerRateProviderAdapter is IRateProvider {

    IDSROracle public immutable dsrOracle;

    constructor(IDSROracle _dsrOracle) {
        dsrOracle = _dsrOracle;
    }

    /**
     * @return The value of sDAI in terms of DAI.
     */
    function getRate() external view override returns (uint256) {
        return dsrOracle.getConversionRateBinomialApprox() / 1e9;
    }

}
