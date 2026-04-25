import AppKit

@MainActor
final class ClockStatusItem {
    let statusItem: NSStatusItem
    private let preferences: ClockPreferences
    private let appState: AppState
    private let clickHandler: (NSEvent) -> Void
    private var updateTimer: Timer?
    private var flashState: Bool = false

    private static let clockFont = NSFont.monospacedDigitSystemFont(
        ofSize: NSFont.systemFontSize,
        weight: .regular
    )

    private static let autosaveName = "QuickCalClock"

    init(
        preferences: ClockPreferences,
        appState: AppState,
        clickHandler: @escaping (NSEvent) -> Void
    ) {
        self.preferences = preferences
        self.appState = appState
        self.clickHandler = clickHandler

        Self.seedPreferredPositionIfNeeded()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = Self.autosaveName
        self.statusItem = item

        configureButton()
        updateDisplay()
        startTimer()
    }

    func tearDown() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func refresh() {
        updateDisplay()
    }

    /// Pre-seed `NSStatusItem Preferred Position <autosaveName>` to 0 on first
    /// launch so macOS places us at the rightmost user-app position. After that,
    /// the autosaveName mechanism owns the value — cmd-dragging the item updates
    /// it, and we must NOT clobber the user's chosen position on later launches.
    private static func seedPreferredPositionIfNeeded() {
        let positionKey = "NSStatusItem Preferred Position \(autosaveName)"
        let seededFlag = "QuickCalClock.positionSeeded"
        if !UserDefaults.standard.bool(forKey: seededFlag) {
            UserDefaults.standard.set(0, forKey: positionKey)
            UserDefaults.standard.set(true, forKey: seededFlag)
        }
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(buttonClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        flashState.toggle()
        updateDisplay()
    }

    private func updateDisplay() {
        switch appState.clockMode {
        case .analogCompanion:
            renderTime()
        case .calendarIcon:
            renderIcon()
        }
    }

    private func renderTime() {
        guard let button = statusItem.button else { return }
        let (text, hideColons) = preferences.formattedTime(flashState: flashState)
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: Self.clockFont,
                .foregroundColor: NSColor.labelColor,
            ]
        )
        if hideColons {
            for range in colonRanges(in: text) {
                attributed.addAttribute(.foregroundColor, value: NSColor.clear, range: range)
            }
        }
        button.image = nil
        button.attributedTitle = attributed
    }

    private func renderIcon() {
        guard let button = statusItem.button else { return }
        let icon = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
        icon?.isTemplate = true
        button.image = icon
        button.attributedTitle = NSAttributedString()
    }

    private func colonRanges(in text: String) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsText = text as NSString
        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let found = nsText.range(of: ":", options: [], range: searchRange)
            if found.location == NSNotFound { break }
            ranges.append(found)
            let nextStart = found.location + found.length
            searchRange = NSRange(location: nextStart, length: nsText.length - nextStart)
        }
        return ranges
    }

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        clickHandler(event)
    }
}
