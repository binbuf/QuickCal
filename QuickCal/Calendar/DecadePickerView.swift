import SwiftUI

struct DecadePickerView: View {
    @Bindable var appState: AppState
    @State private var viewModel: CalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)

    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: CalendarViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(
                title: viewModel.decadeTitle,
                canZoomOut: false,
                onTitleTap: {},
                onPrev: { viewModel.previousDecade() },
                onNext: { viewModel.nextDecade() }
            )

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(viewModel.decadeYears.enumerated()), id: \.offset) { _, entry in
                    yearCell(year: entry.year, isInDecade: entry.isInDecade)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func yearCell(year: Int, isInDecade: Bool) -> some View {
        let isCurrent = viewModel.isCurrentYear(year)

        return Button {
            viewModel.zoomInToYear(year)
            withAnimation(.easeInOut(duration: 0.25)) {
                appState.viewMode = .month
            }
        } label: {
            Text("\(year)")
                .font(.system(size: 13))
                .foregroundStyle(yearForeground(isCurrent: isCurrent, isInDecade: isInDecade))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background {
                    if isCurrent {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor)
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.001))
                }
        }
        .buttonStyle(.plain)
    }

    private func yearForeground(isCurrent: Bool, isInDecade: Bool) -> Color {
        if isCurrent { return .white }
        if !isInDecade { return .secondary.opacity(0.4) }
        return .primary
    }
}
