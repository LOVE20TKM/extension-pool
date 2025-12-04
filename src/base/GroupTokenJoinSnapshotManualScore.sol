// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {GroupTokenJoinSnapshot} from "./GroupTokenJoinSnapshot.sol";
import {
    MAX_ORIGIN_SCORE,
    IGroupScore
} from "../interface/base/IGroupManualScore.sol";
import {ILOVE20Group} from "@group/interfaces/ILOVE20Group.sol";

/// @title GroupTokenJoinSnapshotManualScore
/// @notice Handles manual verification scoring logic for token-join groups
abstract contract GroupTokenJoinSnapshotManualScore is
    GroupTokenJoinSnapshot,
    IGroupScore
{
    // ============ State ============

    /// @dev groupId => delegated verifier address
    mapping(uint256 => address) internal _delegatedVerifierByGroupId;

    /// @dev round => account => origin score [0-100]
    mapping(uint256 => mapping(address => uint256))
        internal _originScoreByAccount;

    /// @dev round => groupId => total score of all accounts in group
    mapping(uint256 => mapping(uint256 => uint256))
        internal _totalScoreByGroupId;

    /// @dev round => groupId => group score (with distrust applied)
    mapping(uint256 => mapping(uint256 => uint256)) internal _scoreByGroupId;

    /// @dev round => total score of all verified groups
    mapping(uint256 => uint256) internal _score;

    /// @dev round => groupId => whether score has been submitted
    mapping(uint256 => mapping(uint256 => bool)) internal _scoreSubmitted;

    /// @dev round => list of verified group ids
    mapping(uint256 => uint256[]) internal _verifiedGroupIds;

    // ============ IGroupScore Implementation ============

    /// @inheritdoc IGroupScore
    function setGroupDelegatedVerifier(
        uint256 groupId,
        address delegatedVerifier
    ) public virtual onlyGroupOwner(groupId) groupActive(groupId) {
        _delegatedVerifierByGroupId[groupId] = delegatedVerifier;
        emit GroupDelegatedVerifierSet(groupId, delegatedVerifier);
    }

    /// @inheritdoc IGroupScore
    function submitOriginScore(
        uint256 groupId,
        uint256[] calldata scores
    ) external virtual {
        _snapshotIfNeeded(groupId);

        uint256 currentRound = _verify.currentRound();

        // Check caller is the verifier at snapshot time or delegated verifier
        address verifier = _snapshotVerifierByGroupId[currentRound][groupId];
        if (
            msg.sender != verifier &&
            msg.sender != _delegatedVerifierByGroupId[groupId]
        ) {
            revert NotVerifier();
        }

        if (_scoreSubmitted[currentRound][groupId]) {
            revert VerificationAlreadySubmitted();
        }

        if (!_hasSnapshot[currentRound][groupId]) {
            revert NoSnapshotForRound();
        }

        // Validate scores array length matches snapshot
        address[] storage accounts = _snapshotAccountsByGroupId[currentRound][
            groupId
        ];
        if (scores.length != accounts.length) {
            revert ScoresCountMismatch();
        }

        // Check verifier capacity limit
        address groupOwner = ILOVE20Group(GROUP_ADDRESS).ownerOf(groupId);
        _checkVerifierCapacity(currentRound, groupOwner, groupId);

        // Process scores and calculate total score
        uint256 totalScore = 0;
        for (uint256 i = 0; i < scores.length; i++) {
            if (scores[i] > MAX_ORIGIN_SCORE) revert ScoreExceedsMax();
            address account = accounts[i];
            _originScoreByAccount[currentRound][account] = scores[i];
            totalScore +=
                scores[i] *
                _snapshotAmountByAccount[currentRound][account];
        }

        _totalScoreByGroupId[currentRound][groupId] = totalScore;

        // Calculate group score (distrust applied by subclass)
        uint256 groupScore = _calculateGroupScore(currentRound, groupId);
        _scoreByGroupId[currentRound][groupId] = groupScore;
        _score[currentRound] += groupScore;

        _scoreSubmitted[currentRound][groupId] = true;
        _verifiedGroupIds[currentRound].push(groupId);

        emit ScoreSubmitted(currentRound, groupId);
    }

    /// @inheritdoc IGroupScore
    function originScoreByAccount(
        uint256 round,
        address account
    ) external view returns (uint256) {
        return _originScoreByAccount[round][account];
    }

    /// @inheritdoc IGroupScore
    function scoreByAccount(
        uint256 round,
        address account
    ) external view returns (uint256) {
        return _calculateScoreByAccount(round, account);
    }

    /// @inheritdoc IGroupScore
    function scoreByGroupId(
        uint256 round,
        uint256 groupId
    ) external view returns (uint256) {
        return _scoreByGroupId[round][groupId];
    }

    /// @inheritdoc IGroupScore
    function score(uint256 round) external view returns (uint256) {
        return _score[round];
    }

    /// @inheritdoc IGroupScore
    function delegatedVerifierByGroupId(
        uint256 groupId
    ) external view returns (address) {
        return _delegatedVerifierByGroupId[groupId];
    }

    /// @inheritdoc IGroupScore
    function canVerify(
        address account,
        uint256 groupId
    ) public view returns (bool) {
        uint256 round = _verify.currentRound();
        address verifier = _snapshotVerifierByGroupId[round][groupId];
        // If no snapshot exists, fall back to current owner
        if (verifier == address(0)) {
            verifier = ILOVE20Group(GROUP_ADDRESS).ownerOf(groupId);
        }
        return
            account == verifier ||
            account == _delegatedVerifierByGroupId[groupId];
    }

    // ============ Internal Functions ============

    function _calculateScoreByAccount(
        uint256 round,
        address account
    ) internal view returns (uint256) {
        uint256 originScoreVal = _originScoreByAccount[round][account];
        if (originScoreVal == 0) return 0;

        uint256 amount = _snapshotAmountByAccount[round][account];
        return originScoreVal * amount;
    }

    function _checkVerifierCapacity(
        uint256 round,
        address groupOwner,
        uint256 currentGroupId
    ) internal view {
        uint256 verifiedCapacity = 0;
        uint256 nftBalance = ILOVE20Group(GROUP_ADDRESS).balanceOf(groupOwner);

        for (uint256 i = 0; i < nftBalance; i++) {
            uint256 groupId = ILOVE20Group(GROUP_ADDRESS).tokenOfOwnerByIndex(
                groupOwner,
                i
            );
            if (groupId != currentGroupId && _scoreSubmitted[round][groupId]) {
                verifiedCapacity += _snapshotAmountByGroupId[round][groupId];
            }
        }

        verifiedCapacity += _snapshotAmountByGroupId[round][currentGroupId];

        uint256 maxCapacity = _calculateMaxCapacityForOwner(groupOwner);
        if (verifiedCapacity > maxCapacity) {
            revert VerifierCapacityExceeded();
        }
    }

    /// @dev Calculate group score - to be overridden by distrust logic
    function _calculateGroupScore(
        uint256 round,
        uint256 groupId
    ) internal view virtual returns (uint256) {
        return _snapshotAmountByGroupId[round][groupId];
    }
}
