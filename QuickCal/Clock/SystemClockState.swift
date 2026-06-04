import Foundation
import AppKit

/// Reads the live state of the macOS menu-bar clock and centralizes the
/// "switch to Analog" guidance shared by onboarding and the right-click tip.
enum SystemClockState {
    /// True when the macOS menu-bar clock is currently set to its analog face.
    ///
    /// Uses CFPreferences with a synchronize so a re-check picks up a change the
    /// user just made in System Settings (a cached `UserDefaults(suiteName:)`
    /// snapshot can go stale within our running process).
    static var isAnalog: Bool {
        let menuClockID = "com.apple.menuextra.clock" as CFString
        CFPreferencesAppSynchronize(menuClockID)
        let value = CFPreferencesCopyAppValue("IsAnalog" as CFString, menuClockID)
        if let number = value as? NSNumber { return number.boolValue }
        return false // key absent ⇒ digital
    }

    static let instructions =
        "Open System Settings → Control Center → Clock Options and set Style to Analog."

    static func openClockSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
