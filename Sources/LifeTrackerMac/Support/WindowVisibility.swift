import AppKit
@MainActor
enum WindowVisibility {
    static func hideDashboard() {
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        NSRunningApplication.current.hide()
    }

    static func showDashboard() {
        ActivityStore.shared.reloadFromDisk()
        NSApp.setActivationPolicy(.accessory)
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
