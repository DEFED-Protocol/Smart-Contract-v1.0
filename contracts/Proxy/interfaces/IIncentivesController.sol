// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
interface IIncentivesController {

    function claimRewards(address[] memory _assets, uint256 amount) external;


}