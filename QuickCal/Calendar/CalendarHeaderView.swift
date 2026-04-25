import SwiftUI

struct CalendarHeaderView: View {
    let title: String
    let canZoomOut: Bool
    let onTitleTap: () -> Void
    let onPrev: () -> Void
    let onNext: () -> Void

    init(
        title: String,
        canZoomOut: Bool = true,
        onTitleTap: @escaping () -> Void,
        onPrev: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.title = title
        self.canZoomOut = canZoomOut
        self.onTitleTap = onTitleTap
        self.onPrev = onPrev
        self.onNext = onNext
    }

    var body: some View {
        HStack {
            Button(action: onTitleTap) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .disabled(!canZoomOut)

            Spacer()

            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}
