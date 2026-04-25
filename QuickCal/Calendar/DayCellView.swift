import SwiftUI

struct DayCellView: View {
    let cell: DayCell
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let eventDots: [Color]

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 34, height: 34)
                }

                if isSelected && !isToday {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }

                if isHovered && !isToday {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 34, height: 34)
                }

                Text("\(cell.day)")
                    .font(.system(size: 13))
                    .foregroundStyle(foregroundColor)
            }
            .frame(width: 38, height: 34)

            HStack(spacing: 2) {
                ForEach(Array(eventDots.prefix(3).enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 5)
        }
        .frame(height: 42)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var foregroundColor: Color {
        if isToday { return .white }
        if !isCurrentMonth { return .secondary.opacity(0.4) }
        return .primary
    }
}
