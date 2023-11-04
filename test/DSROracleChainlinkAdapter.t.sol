// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { DSROracleChainlinkAdapter, IDSROracle } from "../src/adapters/DSROracleChainlinkAdapter.sol";

contract DSROracleMock {
    
    uint256 public chi;

    function getConversionRateBinomialApprox() external view returns (uint256) {
        return chi;
    }

    function setChi(uint256 _chi) external {
        chi = _chi;
    }
    
}

contract DSROracleChainlinkAdapterTest is Test {

    DSROracleMock oracle;

    DSROracleChainlinkAdapter adapter;

    function setUp() public {
        oracle = new DSROracleMock();
        oracle.setChi(1e27);

        adapter = new DSROracleChainlinkAdapter(IDSROracle(address(oracle)));
    }

    function test_constructor() public {
        assertEq(adapter.latestAnswer(), 1e8);
        assertEq(adapter.decimals(), 8);
    }

    function test_price_accumulation() public {
        assertEq(adapter.latestAnswer(), 1e8);

        oracle.setChi(1.01e27);

        assertEq(adapter.latestAnswer(), 1.01e8);
    }

}
