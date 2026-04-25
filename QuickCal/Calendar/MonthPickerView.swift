import SwiftUI

struct MonthPickerView: View {
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
                title: viewModel.yearTitle,
                onTitleTap: zoomOut,
                onPrev: { viewModel.previousYear() },
                onNext: { viewModel.nextYear() }
            )

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(viewModel.monthNames.enumerated()), id: \.offset) { index, name in
                    monthCell(name: name, index: index)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func monthCell(name: String, index: Int) -> some View {
        let isCurrent = viewModel.isCurrentMonth(index)

        return Button {
            viewModel.zoomInToMonth(index)
            appState.displayedMonth = viewModel.displayedMonth
            withAnimation(.easeInOut(duration: 0.25)) {
                appState.viewMode = .day
            }
        } label: {
            Text(name)
                .font(.system(size: 13))
                .foregroundStyle(isCurrent ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
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

    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.viewMode = viewModel.zoomOut(from: appState.viewMode)
        }
    }
}
