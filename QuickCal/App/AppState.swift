import SwiftUI

@Observable
@MainActor
final class AppState {
    var selectedDate: Date = .now
    var displayedMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: .now)
    )!
    var viewMode: ViewMode = .day

    var clockMode: ClockMode = AppState.loadClockMode() {
        didSet { UserDefaults.standard.set(clockMode.rawValue, forKey: "clockMode") }
    }

    var isOnboardingComplete: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingComplete") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingComplete") }
    }

    private static func loadClockMode() -> ClockMode {
        let raw = UserDefaults.standard.string(forKey: "clockMode") ?? ""
        return ClockMode(rawValue: raw) ?? .analogCompanion
    }

    enum ViewMode: Equatable {
        case day
        case month
        case decade
    }

    enum ClockMode: String, CaseIterable {
        case analogCompanion
        case calendarIcon

        var displayName: String {
            switch self {
            case .analogCompanion: return "Analog Companion"
            case .calendarIcon: return "Calendar Icon"
            }
        }
    }
}
