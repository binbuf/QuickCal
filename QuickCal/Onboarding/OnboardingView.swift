import SwiftUI
import AppKit

struct OnboardingView: View {
    @Bindable var appState: AppState
    let onComplete: () -> Void

    @State private var step: Step = .welcome
    @State private var now = Date()
    @State private var isAnalog = false
    @State private var previewClock = ClockPreferences()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum Step {
        case welcome
        case configureMode
        case launchAtLogin
    }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                welcomeView
            case .configureMode:
                configureModeView
                    .onAppear { isAnalog = SystemClockState.isAnalog }
                    .onReceive(ticker) { date in
                        now = date
                        isAnalog = SystemClockState.isAnalog
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                        isAnalog = SystemClockState.isAnalog
                    }
            case .launchAtLogin:
                launchAtLoginView
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
                mode: .calendarIcon,
                title: "Calendar Icon",
                description: "Keep the macOS clock the way you have it. QuickCal shows a small calendar icon — click it to open the flyout.",
                systemImage: "calendar"
            )

            modeCard(
                mode: .analogCompanion,
                title: "Analog Companion",
                description: "Set the macOS clock to its tiny analog face, and let QuickCal be your primary digital readout. Click the clock to see the calendar.",
                systemImage: "clock"
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

                Button("Continue") {
                    step = .launchAtLogin
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Launch at login

    private var launchAtLoginView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "power")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Start QuickCal automatically?")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Keep your calendar a click away every time you log in. You can change this anytime from the right-click menu.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Spacer()

            VStack(spacing: 12) {
                Button("Yes, launch at login") {
                    LaunchAtLoginManager.enable()
                    onComplete()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button("Not now") {
                    onComplete()
                }
                .controlSize(.large)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 4)

            Button("Back") {
                step = .configureMode
            }
            .controlSize(.small)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 10) {
            // Live preview of QuickCal's actual menu-bar readout.
            VStack(alignment: .leading, spacing: 6) {
                Text("This is how QuickCal will look in your menu bar:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Text(previewClock.formattedTime(at: Date()).text)
                        .font(.body.monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.08))
                        )
                    Spacer()
                }
            }

            Divider()

            if isAnalog {
                Label {
                    Text("Your macOS clock is set to Analog — you're all set.")
                        .font(.callout)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Text("Set up the macOS clock")
                    .font(.subheadline.bold())

                Text(SystemClockState.instructions)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Clock Settings") {
                    SystemClockState.openClockSettings()
                }

                Label {
                    Text("Until you switch the macOS clock to Analog, you'll see two clocks in your menu bar.")
                        .font(.caption)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
