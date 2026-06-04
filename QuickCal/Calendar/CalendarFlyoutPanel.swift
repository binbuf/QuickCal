import AppKit
import SwiftUI

@MainActor
final class CalendarFlyoutPanel: NSPanel {
    private var hostingView: NSHostingView<CalendarFlyoutView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 548),
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
        // A behind-window material is composited by the window server, so a layer
        // corner mask doesn't reliably clip it — square corners leak through. The
        // `maskImage` property masks the material itself, giving clean rounded corners.
        visualEffect.maskImage = Self.roundedMaskImage(cornerRadius: 16)

        visualEffect.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
        ])

        contentView = visualEffect
    }

    /// A resizable rounded-rect mask for an `NSVisualEffectView`. The image is built
    /// just large enough to hold the four corners and given cap insets equal to the
    /// radius, so AppKit stretches the straight edges while keeping the corners crisp.
    private static func roundedMaskImage(cornerRadius: CGFloat) -> NSImage {
        let edge = cornerRadius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(
            top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius
        )
        image.resizingMode = .stretch
        return image
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
