// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IDSROracle } from './IDSROracle.sol';

/**
 * @title  IDSRAuthOracle
 * @notice Consolidated DSR reporting along with some convenience functions.
 */
interface IDSRAuthOracle is IDSROracle {

    /** 
     * @notice Emitted when the maxDSR is updated.
     */
    event SetMaxDSR(uint256 maxDSR);

    /**
     * @notice The data provider role.
     */
    function DATA_PROVIDER_ROLE() external view returns (bytes32);

    /**
     * @notice Get the max dsr.
     */
    function maxDSR() external view returns (uint256);

    /**
     * @notice Set the max dsr.
     * @param  maxDSR The max dsr.
     * @dev    Only callable by the admin role.
     */
    function setMaxDSR(uint256 maxDSR) external;

    /**
     * @notice Update the pot data.
     * @param  data The max dsr.
     * @dev    Only callable by the data provider role.
     */
    function setPotData(IDSROracle.PotData calldata data) external;

}
