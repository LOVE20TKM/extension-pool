// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title IGroupReward
/// @notice Interface for group reward queries
interface IGroupReward {
    // ============ Errors ============

    error RewardAlreadyClaimed();
    error NoRewardAvailable();
    error RoundNotFinalized();

    // ============ Events ============

    event RewardClaimed(
        uint256 indexed round,
        uint256 indexed groupId,
        address indexed account,
        uint256 reward,
        uint256 burned
    );

    // ============ Structs ============

    struct RewardInfo {
        uint256 theoreticalReward;
        uint256 actualReward;
        uint256 burnedReward;
        bool claimed;
    }

    // ============ View Functions ============

    function rewardByGroupId(
        uint256 round,
        uint256 groupId
    )
        external
        view
        returns (uint256 theoretical, uint256 actual, uint256 burned);
}
