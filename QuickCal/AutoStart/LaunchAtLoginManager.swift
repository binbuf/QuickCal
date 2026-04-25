import ServiceManagement

enum LaunchAtLoginManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to register login item: \(error)")
        }
    }

    static func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to unregister login item: \(error)")
        }
    }

    static func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
