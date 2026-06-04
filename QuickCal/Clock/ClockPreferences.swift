import Foundation
import Observation

@Observable
@MainActor
final class ClockPreferences {
    var showAMPM: Bool {
        didSet { defaults.set(showAMPM, forKey: Keys.showAMPM) }
    }
    var showSeconds: Bool {
        didSet { defaults.set(showSeconds, forKey: Keys.showSeconds) }
    }
    var showDate: Bool {
        didSet { defaults.set(showDate, forKey: Keys.showDate) }
    }
    var showDayOfWeek: Bool {
        didSet { defaults.set(showDayOfWeek, forKey: Keys.showDayOfWeek) }
    }
    var flashDateSeparators: Bool {
        didSet { defaults.set(flashDateSeparators, forKey: Keys.flashDateSeparators) }
    }

    @ObservationIgnored
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let seeded = "clockPrefs.seeded"
        static let showAMPM = "clockPrefs.showAMPM"
        static let showSeconds = "clockPrefs.showSeconds"
        static let showDate = "clockPrefs.showDate"
        static let showDayOfWeek = "clockPrefs.showDayOfWeek"
        static let flashDateSeparators = "clockPrefs.flashDateSeparators"
    }

    init() {
        if !UserDefaults.standard.bool(forKey: Keys.seeded) {
            Self.seedFromSystemClock()
            UserDefaults.standard.set(true, forKey: Keys.seeded)
        }
        showAMPM = UserDefaults.standard.bool(forKey: Keys.showAMPM)
        showSeconds = UserDefaults.standard.bool(forKey: Keys.showSeconds)
        showDate = UserDefaults.standard.bool(forKey: Keys.showDate)
        showDayOfWeek = UserDefaults.standard.bool(forKey: Keys.showDayOfWeek)
        flashDateSeparators = UserDefaults.standard.bool(forKey: Keys.flashDateSeparators)
    }

    /// Read once from com.apple.menuextra.clock so the user starts with the same values
    /// they had configured on the OS clock. After this seed, our prefs are independent.
    private static func seedFromSystemClock() {
        let osDefaults = UserDefaults(suiteName: "com.apple.menuextra.clock")
        let std = UserDefaults.standard
        std.set(osDefaults?.object(forKey: "ShowAMPM") as? Bool ?? true, forKey: Keys.showAMPM)
        std.set(osDefaults?.object(forKey: "ShowSeconds") as? Bool ?? false, forKey: Keys.showSeconds)
        std.set(osDefaults?.object(forKey: "ShowDayOfWeek") as? Bool ?? true, forKey: Keys.showDayOfWeek)
        std.set(osDefaults?.object(forKey: "FlashDateSeparators") as? Bool ?? false, forKey: Keys.flashDateSeparators)
        let osShowDate = osDefaults?.object(forKey: "ShowDate") as? Int ?? 0
        std.set(osShowDate != 0, forKey: Keys.showDate)
    }

    func buildDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        var components: [String] = []

        if showDayOfWeek {
            components.append("EEE")
        }

        if showDayOfWeek || showDate {
            components.append("MMM d")
        }

        components.append(timeFormatString())
        formatter.dateFormat = components.joined(separator: "  ")
        return formatter
    }

    func buildTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = timeFormatString()
        return formatter
    }

    private func timeFormatString() -> String {
        let is24Hour = !showAMPM
        if showSeconds {
            return is24Hour ? "HH:mm:ss" : "h:mm:ss a"
        } else {
            return is24Hour ? "HH:mm" : "h:mm a"
        }
    }

    /// Whether the time separators should be hidden at `date` for the flash effect.
    /// Hidden during the back half of each whole second so the blink toggles on the
    /// half-second boundary, in lock-step with the OS clock. No-op unless enabled.
    func separatorsHidden(at date: Date) -> Bool {
        guard flashDateSeparators else { return false }
        let fraction = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.0)
        return fraction > 0.25 && fraction < 0.75
    }

    /// Date + time string for an explicit `date` (driven by the aligned clock tick)
    /// so the displayed value matches the wall clock.
    func formattedTime(at date: Date) -> (text: String, hideColons: Bool) {
        let text = buildDateFormatter().string(from: date)
        return (text, separatorsHidden(at: date))
    }

    /// Time-only string for an explicit `date`, with the same alignment guarantees.
    func formattedTimeOnly(at date: Date) -> (text: String, hideColons: Bool) {
        let text = buildTimeFormatter().string(from: date)
        return (text, separatorsHidden(at: date))
    }
}
