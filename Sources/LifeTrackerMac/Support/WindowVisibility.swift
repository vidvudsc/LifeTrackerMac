import AppKit

@MainActor
enum WindowVisibility {
    static func hideDashboard() {
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
    }

    static func showDashboard() {
        ActivityStore.shared.reloadFromDisk()
        NSApp.setActivationPolicy(.regular)
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
