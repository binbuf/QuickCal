import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState
    let onComplete: () -> Void

    @State private var step: Step = .welcome

    enum Step {
        case welcome
        case configureMode
    }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                welcomeView
            case .configureMode:
                configureModeView
            }
        }
        .frame(width: 520, height: 560)
        .padding(40)
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Welcome to QuickCal")
                .font(.largeTitle.bold())

            Text("A calendar flyout for your menu bar — just like Windows 11, native to macOS.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Spacer()

            Button("Continue") {
                step = .configureMode
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)

            Spacer().frame(height: 16)
        }
    }

    // MARK: - Mode picker

    private var configureModeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose how QuickCal appears")
                .font(.title2.bold())

            Text("macOS does not let third-party apps hide the system menu-bar clock. Pick how you'd like QuickCal to coexist with it.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            modeCard(
                mode: .analogCompanion,
                title: "Analog Companion",
                description: "Set the macOS clock to its tiny analog face, and let QuickCal be your primary digital readout. Customizable format via the right-click menu.",
                systemImage: "clock"
            )

            modeCard(
                mode: .calendarIcon,
                title: "Calendar Icon",
                description: "Keep the macOS clock the way you have it. QuickCal shows a small calendar icon — click it to open the flyout.",
                systemImage: "calendar"
            )

            if appState.clockMode == .analogCompanion {
                analogInstructions
            }

            Spacer(minLength: 12)

            HStack {
                Button("Back") {
                    step = .welcome
                }
                .controlSize(.large)

                Spacer()

                Button("Get Started") {
                    onComplete()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func modeCard(mode: AppState.ClockMode, title: String, description: String, systemImage: String) -> some View {
        let isSelected = appState.clockMode == mode
        return Button {
            appState.clockMode = mode
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var analogInstructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set up the macOS clock")
                .font(.subheadline.bold())

            Text("Open System Settings → Control Center → Clock Options, and set Style to Analog. Then come back here.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button("Open Control Center Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
