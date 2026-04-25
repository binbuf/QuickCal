import AppKit
import SwiftUI

@MainActor
final class CalendarFlyoutPanel: NSPanel {
    private var hostingView: NSHostingView<CalendarFlyoutView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 620),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        isFloatingPanel = true
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovable = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func setupContent(appState: AppState, eventStore: EventStoreManager, preferences: ClockPreferences) {
        let flyoutView = CalendarFlyoutView(
            appState: appState,
            eventStore: eventStore,
            preferences: preferences
        ) { [weak self] in
            self?.orderOut(nil)
        }

        let hosting = NSHostingView(rootView: flyoutView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        self.hostingView = hosting

        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true

        visualEffect.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
        ])

        contentView = visualEffect
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            orderOut(nil)
            return
        }
        super.keyDown(with: event)
    }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }
}
