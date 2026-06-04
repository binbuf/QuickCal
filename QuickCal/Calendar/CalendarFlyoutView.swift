import SwiftUI

struct CalendarFlyoutView: View {
    @Bindable var appState: AppState
    var eventStore: EventStoreManager
    let preferences: ClockPreferences
    var dismiss: () -> Void

    /// Half-second resolution when flashing the separators (so the colon can
    /// blink on the half-second boundary), otherwise a plain one-second tick.
    private var tickInterval: TimeInterval {
        preferences.flashDateSeparators ? 0.5 : 1.0
    }

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.alignedTo(tickInterval)) { context in
                clockHeader(date: context.date)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
            }

            Divider()
                .padding(.horizontal, 16)

            calendarContent
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 4)

            AgendaListView(date: appState.selectedDate, eventStore: eventStore)
                .frame(maxHeight: 108)
                .padding(.bottom, 12)
        }
        .frame(width: 340)
    }

    // MARK: - Clock Header

    private func clockHeader(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timeAttributedString(for: date))
                .font(.system(size: 44, weight: .light, design: .default))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Button {
                let cal = Calendar.current
                let isCurrentMonth = cal.isDate(appState.displayedMonth, equalTo: .now, toGranularity: .month)
                if !isCurrentMonth {
                    appState.displayedMonth = cal.date(
                        from: cal.dateComponents([.year, .month], from: .now)
                    )!
                    appState.viewMode = .day
                }
            } label: {
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeAttributedString(for date: Date) -> AttributedString {
        let (text, hideColons) = preferences.formattedTimeOnly(at: date)
        var attributed = AttributedString(text)
        if hideColons {
            var idx = attributed.startIndex
            while idx < attributed.endIndex {
                let next = attributed.index(afterCharacter: idx)
                if attributed.characters[idx] == ":" {
                    attributed[idx..<next].foregroundColor = .clear
                }
                idx = next
            }
        }
        return attributed
    }

    // MARK: - Calendar Content

    @ViewBuilder
    private var calendarContent: some View {
        ZStack {
            switch appState.viewMode {
            case .day:
                MonthGridView(appState: appState, eventStore: eventStore)
                    .transition(dayTransition)
            case .month:
                MonthPickerView(appState: appState)
                    .transition(monthTransition)
            case .decade:
                DecadePickerView(appState: appState)
                    .transition(decadeTransition)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.viewMode)
        .frame(height: 322, alignment: .top)
        .clipped()
    }

    // MARK: - Transitions (matching Harbor's 250ms scale+fade)

    private var dayTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.6).combined(with: .opacity),
            removal: .scale(scale: 1.4).combined(with: .opacity)
        )
    }

    private var monthTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 1.4).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
        )
    }

    private var decadeTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 1.4).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
        )
    }
}

/// A timeline schedule whose ticks land on wall-clock boundaries (e.g. exactly on
/// each whole or half second) rather than drifting from the moment the view first
/// appeared. This keeps the rendered time changing in lock-step with the OS clock.
struct AlignedTimelineSchedule: TimelineSchedule {
    let interval: TimeInterval

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let step = interval
        let start = startDate.timeIntervalSinceReferenceDate
        // First tick: the next boundary strictly after `startDate`.
        var tick = (start / step).rounded(.down) * step
        if tick <= start { tick += step }
        return AnyIterator {
            let date = Date(timeIntervalSinceReferenceDate: tick)
            tick += step
            return date
        }
    }
}

extension TimelineSchedule where Self == AlignedTimelineSchedule {
    /// Ticks aligned to wall-clock boundaries of length `interval` seconds.
    static func alignedTo(_ interval: TimeInterval) -> AlignedTimelineSchedule {
        AlignedTimelineSchedule(interval: interval)
    }
}
