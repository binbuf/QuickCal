import Foundation

struct DayCell: Identifiable {
    let id: Int
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
}

@Observable
@MainActor
final class CalendarViewModel {
    private let calendar = Calendar.current

    var displayedMonth: Date
    var displayYear: Int
    var displayDecadeStart: Int
    var selectedDate: Date

    init(appState: AppState) {
        self.displayedMonth = appState.displayedMonth
        self.displayYear = Calendar.current.component(.year, from: appState.displayedMonth)
        self.displayDecadeStart = Calendar.current.component(.year, from: appState.displayedMonth) / 10 * 10
        self.selectedDate = appState.selectedDate
    }

    // MARK: - Day View

    var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: displayedMonth)
    }

    var dayOfWeekSymbols: [String] {
        calendar.veryShortWeekdaySymbols
    }

    var dayCells: [DayCell] {
        let first = displayedMonth
        let weekday = calendar.component(.weekday, from: first)
        let startOffset = -(weekday - calendar.firstWeekday)
        let adjustedOffset = startOffset > 0 ? startOffset - 7 : startOffset

        return (0..<42).map { i in
            let date = calendar.date(byAdding: .day, value: adjustedOffset + i, to: first)!
            return DayCell(
                id: i,
                date: date,
                day: calendar.component(.day, from: date),
                isCurrentMonth: calendar.isDate(date, equalTo: first, toGranularity: .month)
            )
        }
    }

    func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
    }

    func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            )!
        }
    }

    // MARK: - Month View

    var yearTitle: String {
        "\(displayYear)"
    }

    var monthNames: [String] {
        calendar.shortMonthSymbols
    }

    func isCurrentMonth(_ monthIndex: Int) -> Bool {
        let now = Date()
        return displayYear == calendar.component(.year, from: now)
            && (monthIndex + 1) == calendar.component(.month, from: now)
    }

    func selectMonth(_ monthIndex: Int) {
        let month = monthIndex + 1
        displayedMonth = calendar.date(
            from: DateComponents(year: displayYear, month: month, day: 1)
        )!
    }

    func previousYear() {
        displayYear -= 1
    }

    func nextYear() {
        displayYear += 1
    }

    // MARK: - Decade View

    var decadeTitle: String {
        "\(displayDecadeStart)\u{2013}\(displayDecadeStart + 9)"
    }

    var decadeYears: [(year: Int, isInDecade: Bool)] {
        (-1..<11).map { offset in
            let year = displayDecadeStart + offset
            let isInDecade = year >= displayDecadeStart && year <= displayDecadeStart + 9
            return (year, isInDecade)
        }
    }

    func isCurrentYear(_ year: Int) -> Bool {
        year == calendar.component(.year, from: Date())
    }

    func selectYear(_ year: Int) {
        displayYear = year
    }

    func previousDecade() {
        displayDecadeStart -= 10
    }

    func nextDecade() {
        displayDecadeStart += 10
    }

    // MARK: - Zoom

    func zoomOut(from viewMode: AppState.ViewMode) -> AppState.ViewMode {
        switch viewMode {
        case .day:
            displayYear = calendar.component(.year, from: displayedMonth)
            return .month
        case .month:
            displayDecadeStart = displayYear / 10 * 10
            return .decade
        case .decade:
            return .decade
        }
    }

    func zoomInToMonth(_ monthIndex: Int) {
        selectMonth(monthIndex)
    }

    func zoomInToYear(_ year: Int) {
        displayYear = year
    }
}
