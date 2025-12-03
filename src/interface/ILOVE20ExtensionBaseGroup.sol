// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IExtensionCore} from "@extension/src/interface/base/IExtensionCore.sol";
import {IExtensionAccounts} from "@extension/src/interface/base/IExtensionAccounts.sol";
import {IExtensionVerificationInfo} from "@extension/src/interface/base/IExtensionVerificationInfo.sol";
import {IGroupCore} from "./base/IGroupCore.sol";
import {ILOVE20Extension} from "@extension/src/interface/ILOVE20Extension.sol";

/// @title ILOVE20ExtensionBaseGroup
/// @notice Interface for group-based LOVE20 extensions
interface ILOVE20ExtensionBaseGroup is
    IExtensionCore,
    IExtensionAccounts,
    IExtensionVerificationInfo,
    IGroupCore,
    ILOVE20Extension
{
    // No additional functions needed
    // joinedValue, joinedValueByAccount, and isJoinedValueCalculated
    // are inherited from ILOVE20Extension -> IExtensionJoinedValue
}

