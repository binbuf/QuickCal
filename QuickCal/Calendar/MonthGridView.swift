import SwiftUI

struct MonthGridView: View {
    @Bindable var appState: AppState
    var eventStore: EventStoreManager

    @State private var viewModel: CalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    init(appState: AppState, eventStore: EventStoreManager) {
        self.appState = appState
        self.eventStore = eventStore
        self._viewModel = State(initialValue: CalendarViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(
                title: viewModel.monthYearTitle,
                onTitleTap: zoomOut,
                onPrev: {
                    viewModel.previousMonth()
                    syncToAppState()
                    fetchEvents()
                },
                onNext: {
                    viewModel.nextMonth()
                    syncToAppState()
                    fetchEvents()
                }
            )

            dayOfWeekHeaders

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.dayCells) { cell in
                    DayCellView(
                        cell: cell,
                        isToday: Calendar.current.isDateInToday(cell.date),
                        isSelected: Calendar.current.isDate(cell.date, inSameDayAs: viewModel.selectedDate),
                        isCurrentMonth: cell.isCurrentMonth,
                        eventDots: eventStore.eventColors(for: cell.date)
                    )
                    .onTapGesture {
                        viewModel.selectDate(cell.date)
                        appState.selectedDate = cell.date
                        syncToAppState()
                    }
                }
            }
        }
        .onAppear {
            fetchEvents()
        }
        .onChange(of: appState.displayedMonth) { _, newValue in
            viewModel.displayedMonth = newValue
            fetchEvents()
        }
    }

    private var dayOfWeekHeaders: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(viewModel.dayOfWeekSymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(height: 24)
            }
        }
    }

    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.viewMode = viewModel.zoomOut(from: appState.viewMode)
        }
    }

    private func syncToAppState() {
        appState.displayedMonth = viewModel.displayedMonth
    }

    private func fetchEvents() {
        eventStore.fetchEvents(for: viewModel.displayedMonth)
    }
}
