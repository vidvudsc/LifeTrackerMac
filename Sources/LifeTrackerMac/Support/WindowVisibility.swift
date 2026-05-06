import AppKit

@MainActor
enum WindowVisibility {
    static func hideDashboard() {
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.post(name: .lifeTrackerHideStatusItem, object: nil)
    }

    static func showDashboard() {
        ActivityStore.shared.reloadFromDisk()
        NotificationCenter.default.post(name: .lifeTrackerShowStatusItem, object: nil)
        NSApp.setActivationPolicy(.regular)
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
