// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 Pivotfrag LLC

/// One-time reminder for people updating from 0.4.0. That version used another bundle ID, so its login item
/// doesn't start the current app; macOS offers no way to move it over, so the user has to turn it on again.
enum LoginReminder {
    static let productBundleID = "com.pivotfrag.keenquad"
    static let legacyBundleID = "com.keenquad.app"
    /// UserDefaults key: the reminder was shown, or isn't needed any more.
    static let doneKey = "loginReminderDone"

    enum Decision: Equatable {
        case nothing   // not this build, already handled, or never used 0.4.0
        case markDone  // Launch at Login is already on: never ask
        case show
    }

    /// - Parameters:
    ///   - legacySettingsExist: 0.4.0's preferences are still there, so this Mac used 0.4.0.
    static func decide(isProduct: Bool, legacySettingsExist: Bool, loginEnabled: Bool, alreadyDone: Bool) -> Decision {
        guard isProduct, !alreadyDone, legacySettingsExist else { return .nothing }
        return loginEnabled ? .markDone : .show
    }
}
