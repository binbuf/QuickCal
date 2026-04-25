import AppKit
import SwiftUI
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var clockPreferences: ClockPreferences?
    private var clockStatusItem: ClockStatusItem?
    private var flyoutPanel: CalendarFlyoutPanel?
    private var eventStoreManager: EventStoreManager?
    private var onboardingWindow: OnboardingWindow?
    private var globalClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if appState.isOnboardingComplete {
            setupMenuBar()
        } else {
            showOnboarding()
        }
    }

    // MARK: - Onboarding

    func showOnboarding() {
        onboardingWindow = OnboardingWindow(appState: appState) { [weak self] in
            self?.onboardingComplete()
        }
        onboardingWindow?.show()
    }

    private func onboardingComplete() {
        appState.isOnboardingComplete = true
        onboardingWindow?.close()
        onboardingWindow = nil
        setupMenuBar()
    }

    // MARK: - Menu Bar Setup

    func setupMenuBar() {
        let eventStore = EventStoreManager()
        self.eventStoreManager = eventStore

        Task {
            await eventStore.ensureAccessOrPrompt()
        }

        let preferences = ClockPreferences()
        self.clockPreferences = preferences
        let statusItem = ClockStatusItem(preferences: preferences, appState: appState) { [weak self] event in
            self?.statusItemClicked(event: event)
        }
        self.clockStatusItem = statusItem

        let panel = CalendarFlyoutPanel()
        panel.setupContent(appState: appState, eventStore: eventStore, preferences: preferences)
        self.flyoutPanel = panel
    }

    // MARK: - Status Item Actions

    private func statusItemClicked(event: NSEvent) {
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleFlyout()
        }
    }

    func toggleFlyout() {
        guard let panel = flyoutPanel else { return }

        if panel.isVisible {
            closeFlyout()
        } else {
            openFlyout()
        }
    }

    private func openFlyout() {
        guard let panel = flyoutPanel,
              let button = clockStatusItem?.statusItem.button,
              let buttonWindow = button.window else { return }

        if let eventStore = eventStoreManager {
            eventStore.fetchEvents(for: appState.displayedMonth)
        }

        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let panelWidth = panel.frame.width
        let x = buttonFrame.maxX - panelWidth
        let y = buttonFrame.minY - panel.frame.height - 4

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self, let panel = self.flyoutPanel else { return }
            let screenPoint = NSEvent.mouseLocation
            if !panel.frame.contains(screenPoint) {
                self.closeFlyout()
            }
        }
    }

    func closeFlyout() {
        flyoutPanel?.orderOut(nil)
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(title: "About QuickCal", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        // Display Mode submenu
        let modeItem = NSMenuItem(title: "Display Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = buildDisplayModeMenu()
        menu.addItem(modeItem)

        // Clock Options submenu (analog companion mode shows time text — these toggles drive its format)
        let optionsItem = NSMenuItem(title: "Clock Options", action: nil, keyEquivalent: "")
        optionsItem.submenu = buildClockOptionsMenu()
        if appState.clockMode != .analogCompanion {
            optionsItem.isEnabled = false
            optionsItem.toolTip = "Available in Analog Companion mode"
        }
        menu.addItem(optionsItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LaunchAtLoginManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let uninstallItem = NSMenuItem(
            title: "Uninstall QuickCal\u{2026}",
            action: #selector(uninstallApp),
            keyEquivalent: ""
        )
        uninstallItem.target = self
        menu.addItem(uninstallItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit QuickCal", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        clockStatusItem?.statusItem.menu = menu
        clockStatusItem?.statusItem.button?.performClick(nil)
        clockStatusItem?.statusItem.menu = nil
    }

    private func buildDisplayModeMenu() -> NSMenu {
        let submenu = NSMenu()
        for mode in AppState.ClockMode.allCases {
            let item = NSMenuItem(
                title: mode.displayName,
                action: #selector(selectClockMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = appState.clockMode == mode ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    private func buildClockOptionsMenu() -> NSMenu {
        let submenu = NSMenu()
        guard let preferences = clockPreferences else { return submenu }

        addToggle(to: submenu, title: "Show Date", state: preferences.showDate, action: #selector(toggleShowDate))
        addToggle(to: submenu, title: "Show Day of Week", state: preferences.showDayOfWeek, action: #selector(toggleShowDayOfWeek))
        addToggle(to: submenu, title: "Show AM/PM", state: preferences.showAMPM, action: #selector(toggleShowAMPM))
        addToggle(to: submenu, title: "Show Seconds", state: preferences.showSeconds, action: #selector(toggleShowSeconds))
        addToggle(to: submenu, title: "Flash the Time Separators", state: preferences.flashDateSeparators, action: #selector(toggleFlashSeparators))

        return submenu
    }

    private func addToggle(to menu: NSMenu, title: String, state: Bool, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = state ? .on : .off
        menu.addItem(item)
    }

    @objc private func selectClockMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = AppState.ClockMode(rawValue: raw) else { return }
        appState.clockMode = mode
        clockStatusItem?.refresh()
    }

    @objc private func toggleShowDate() {
        clockPreferences?.showDate.toggle()
        clockStatusItem?.refresh()
    }

    @objc private func toggleShowDayOfWeek() {
        clockPreferences?.showDayOfWeek.toggle()
        clockStatusItem?.refresh()
    }

    @objc private func toggleShowAMPM() {
        clockPreferences?.showAMPM.toggle()
        clockStatusItem?.refresh()
    }

    @objc private func toggleShowSeconds() {
        clockPreferences?.showSeconds.toggle()
        clockStatusItem?.refresh()
    }

    @objc private func toggleFlashSeparators() {
        clockPreferences?.flashDateSeparators.toggle()
        clockStatusItem?.refresh()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginManager.toggle()
    }

    @objc private func uninstallApp() {
        closeFlyout()
        UninstallManager.confirmAndUninstall(statusItem: clockStatusItem)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
