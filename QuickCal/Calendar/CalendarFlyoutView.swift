import SwiftUI

struct CalendarFlyoutView: View {
    @Bindable var appState: AppState
    var eventStore: EventStoreManager
    let preferences: ClockPreferences
    var dismiss: () -> Void

    @State private var currentTime = Date()
    @State private var flashState = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            clockHeader
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            calendarContent
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 4)

            AgendaListView(date: appState.selectedDate, eventStore: eventStore)
                .frame(maxHeight: 180)
                .padding(.bottom, 12)
        }
        .frame(width: 340)
        .onReceive(timer) { time in
            currentTime = time
            flashState.toggle()
        }
    }

    // MARK: - Clock Header

    private var clockHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timeAttributedString)
                .font(.system(size: 44, weight: .light, design: .default))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Text(currentTime, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeAttributedString: AttributedString {
        _ = currentTime  // tie this property to the per-second tick
        let (text, hideColons) = preferences.formattedTimeOnly(flashState: flashState)
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
