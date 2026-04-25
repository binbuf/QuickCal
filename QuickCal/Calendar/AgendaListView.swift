import SwiftUI

struct AgendaListView: View {
    let date: Date
    var eventStore: EventStoreManager

    var body: some View {
        let events = eventStore.events(for: date)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if events.isEmpty {
                    emptyState
                } else {
                    ForEach(events) { event in
                        eventRow(event)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var emptyState: some View {
        Text("No events")
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 20)
            .padding(.top, 4)
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(event.calendarColor)
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(event.timeString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
