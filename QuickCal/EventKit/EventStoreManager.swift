import AppKit
import EventKit
import Observation
import SwiftUI

@Observable
@MainActor
final class EventStoreManager {
    let store = EKEventStore()
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private var cachedEvents: [Date: [CalendarEvent]] = [:]
    private var cachedMonths: Set<String> = []

    @ObservationIgnored
    private var changeObserver: NSObjectProtocol?

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.invalidateCache()
            }
        }
    }

    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                let granted = try await store.requestFullAccessToEvents()
                authorizationStatus = granted ? .fullAccess : .denied
            } catch {
                authorizationStatus = .denied
            }
        } else {
            let granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in
                    cont.resume(returning: granted)
                }
            }
            authorizationStatus = granted ? .fullAccess : .denied
        }
    }

    /// Re-read the current TCC authorization, request if undetermined, and surface
    /// a clear alert + System Settings shortcut if the user has revoked access. This
    /// runs every launch so revocations between sessions don't fail silently.
    func ensureAccessOrPrompt() async {
        // Always read fresh — the stored property could be stale if the user revoked
        // permission via System Settings since the last launch.
        let live = EKEventStore.authorizationStatus(for: .event)
        authorizationStatus = live

        switch live {
        case .notDetermined:
            await requestAccess()
            if authorizationStatus != .fullAccess {
                presentDeniedAlert()
            }
        case .denied, .restricted:
            presentDeniedAlert()
        case .fullAccess, .writeOnly:
            break
        @unknown default:
            break
        }
    }

    private func presentDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Calendar access required"
        alert.informativeText = """
            QuickCal needs Calendar access to show events in the flyout. Access is currently denied.

            Open System Settings → Privacy & Security → Calendars and turn QuickCal on.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Privacy Settings")
        alert.addButton(withTitle: "Skip")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func fetchEvents(for month: Date) {
        guard authorizationStatus == .fullAccess else { return }

        let calendar = Calendar.current
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }

        let monthKey = "\(calendar.component(.year, from: month))-\(calendar.component(.month, from: month))"
        guard !cachedMonths.contains(monthKey) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        for event in ekEvents {
            let dayStart = calendar.startOfDay(for: event.startDate)
            let calEvent = CalendarEvent(from: event)
            cachedEvents[dayStart, default: []].append(calEvent)
        }

        // Sort events within each day by time
        for (day, events) in cachedEvents {
            cachedEvents[day] = events.sorted { a, b in
                if a.isAllDay != b.isAllDay { return a.isAllDay }
                return a.startDate < b.startDate
            }
        }

        cachedMonths.insert(monthKey)
    }

    func events(for date: Date) -> [CalendarEvent] {
        let dayStart = Calendar.current.startOfDay(for: date)
        return cachedEvents[dayStart] ?? []
    }

    func eventColors(for date: Date) -> [Color] {
        let dayEvents = events(for: date)
        var seen = Set<String>()
        var colors: [Color] = []
        for event in dayEvents {
            if seen.insert(event.calendarTitle).inserted {
                colors.append(event.calendarColor)
            }
            if colors.count >= 3 { break }
        }
        return colors
    }

    func invalidateCache() {
        cachedEvents.removeAll()
        cachedMonths.removeAll()
    }
}
