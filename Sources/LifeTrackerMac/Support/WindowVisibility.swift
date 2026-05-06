import AppKit

@MainActor
enum WindowVisibility {
    static func hideDashboard() {
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.orderOut(nil)
        }
        StatusBarController.hideCurrentItem()
        NSApp.hide(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    static func showDashboard() {
        ActivityStore.shared.reloadFromDisk()
        StatusBarController.showCurrentItem()
        NSApp.setActivationPolicy(.regular)
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
