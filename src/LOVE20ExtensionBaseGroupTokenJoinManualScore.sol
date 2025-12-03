// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {
    GroupTokenJoinSnapshotManualScoreDistrustReward
} from "./base/GroupTokenJoinSnapshotManualScoreDistrustReward.sol";
import {GroupTokenJoin} from "./base/GroupTokenJoin.sol";
import {GroupCore} from "./base/GroupCore.sol";
import {ExtensionAccounts} from "@extension/src/base/ExtensionAccounts.sol";
import {
    ExtensionVerificationInfo
} from "@extension/src/base/ExtensionVerificationInfo.sol";
import {ILOVE20Extension} from "@extension/src/interface/ILOVE20Extension.sol";
import {IExtensionExit} from "@extension/src/interface/base/IExtensionExit.sol";
import {IGroupManualScore} from "./interface/base/IGroupManualScore.sol";

/// @title LOVE20ExtensionBaseGroupTokenJoinManualScore
/// @notice Extension contract for manual scoring verification in group-based actions
/// @dev Combines GroupReward (includes Snapshot, Score, Distrust) with Extension interfaces
abstract contract LOVE20ExtensionBaseGroupTokenJoinManualScore is
    GroupTokenJoinSnapshotManualScoreDistrustReward,
    ExtensionAccounts,
    ExtensionVerificationInfo,
    ILOVE20Extension,
    IGroupManualScore
{
    // ============ Constructor ============

    constructor(
        address factory_,
        address tokenAddress_,
        address groupAddress_,
        address stakeTokenAddress_,
        address joinTokenAddress_,
        uint256 minGovernanceVoteRatio_,
        uint256 capacityMultiplier_,
        uint256 stakingMultiplier_,
        uint256 maxJoinAmountMultiplier_,
        uint256 minJoinAmount_
    )
        GroupTokenJoinSnapshotManualScoreDistrustReward()
        GroupCore(
            factory_,
            tokenAddress_,
            groupAddress_,
            stakeTokenAddress_,
            minGovernanceVoteRatio_,
            capacityMultiplier_,
            stakingMultiplier_,
            maxJoinAmountMultiplier_,
            minJoinAmount_
        )
        GroupTokenJoin(joinTokenAddress_)
    {}

    // ============ Override: Account Management ============

    function _addAccount(
        address account
    ) internal override(ExtensionAccounts, GroupTokenJoin) {
        ExtensionAccounts._addAccount(account);
    }

    function _removeAccount(
        address account
    ) internal override(ExtensionAccounts, GroupTokenJoin) {
        ExtensionAccounts._removeAccount(account);
    }

    // ============ Override: Exit ============

    function exit() public override(GroupTokenJoin, IExtensionExit) {
        GroupTokenJoin.exit();
    }
}
