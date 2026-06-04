import AppKit

@MainActor
final class ClockStatusItem {
    let statusItem: NSStatusItem
    private let preferences: ClockPreferences
    private let appState: AppState
    private let clickHandler: (NSEvent) -> Void
    private var updateTimer: Timer?

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
        // Re-aim the timer so a freshly toggled flash setting picks up the
        // half-second cadence (or drops back to one second) right away.
        restartTimer()
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
        scheduleNextTick()
    }

    private func restartTimer() {
        updateTimer?.invalidate()
        scheduleNextTick()
    }

    /// Schedule a one-shot timer for the next wall-clock boundary — a half-second
    /// while flashing the separators, otherwise a whole second — and reschedule
    /// after each fire. Re-aiming at the boundary every tick keeps us aligned with
    /// the OS clock instead of drifting from an arbitrary launch offset, the way a
    /// fixed repeating timer would.
    private func scheduleNextTick() {
        let flashing = appState.clockMode == .analogCompanion && preferences.flashDateSeparators
        let interval: TimeInterval = flashing ? 0.5 : 1.0
        let now = Date().timeIntervalSinceReferenceDate
        var next = (now / interval).rounded(.down) * interval
        if next <= now { next += interval }
        let fireDate = Date(timeIntervalSinceReferenceDate: next)
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.tick(at: fireDate)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }

    private func tick(at date: Date) {
        updateDisplay(at: date)
        scheduleNextTick()
    }

    private func updateDisplay(at date: Date = Date()) {
        switch appState.clockMode {
        case .analogCompanion:
            renderTime(at: date)
        case .calendarIcon:
            renderIcon()
        }
    }

    private func renderTime(at date: Date) {
        guard let button = statusItem.button else { return }
        let (text, hideColons) = preferences.formattedTime(at: date)
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
