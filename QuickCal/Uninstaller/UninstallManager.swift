import AppKit
import ServiceManagement

@MainActor
enum UninstallManager {
    static func confirmAndUninstall(statusItem: ClockStatusItem?) {
        let alert = NSAlert()
        alert.messageText = "Uninstall QuickCal?"
        alert.informativeText = "This will remove QuickCal's menu bar item, unregister the login item, and delete all preferences. QuickCal will then quit. Your macOS menu bar clock will return to its normal appearance after you re-enable it manually in Control Center settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            performUninstall(statusItem: statusItem)
        }
    }

    private static func performUninstall(statusItem: ClockStatusItem?) {
        // 1. Remove status item
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item.statusItem)
        }

        // 2. Unregister login item
        try? SMAppService.mainApp.unregister()

        // 3. Delete preferences
        if let bid = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bid)
            UserDefaults.standard.synchronize()
        }

        // 4. Remove app support directory
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let quickCalDir = appSupport.appendingPathComponent("QuickCal")
            try? FileManager.default.removeItem(at: quickCalDir)
        }

        // 5. Quit
        NSApp.terminate(nil)
    }
}
