import AppKit
import SwiftUI
import EventKit

struct CalendarEvent: Identifiable {
    let id: String
    let calendarItemIdentifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: Color
    let calendarTitle: String

    init(from ekEvent: EKEvent) {
        self.calendarItemIdentifier = ekEvent.calendarItemIdentifier
        self.id = ekEvent.eventIdentifier ?? ekEvent.calendarItemIdentifier
        self.title = ekEvent.title ?? "Untitled"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.calendarTitle = ekEvent.calendar?.title ?? ""
        if let cgColor = ekEvent.calendar?.cgColor {
            self.calendarColor = Color(cgColor: cgColor)
        } else {
            self.calendarColor = .accentColor
        }
    }

    /// Open Calendar.app and reveal this event. Uses the long-standing (undocumented)
    /// `ical://ekevent/<calendarItemIdentifier>` URL scheme. Failure is silent — Calendar.app
    /// just opens to today.
    func revealInCalendarApp() {
        guard let url = URL(string: "ical://ekevent/\(calendarItemIdentifier)?method=show&options=more") else { return }
        NSWorkspace.shared.open(url)
    }

    var timeString: String {
        if isAllDay {
            return "All Day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startDate)) \u{2013} \(formatter.string(from: endDate))"
    }
}
