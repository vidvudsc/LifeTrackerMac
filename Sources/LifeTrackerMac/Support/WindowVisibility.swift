import AppKit
@MainActor
enum WindowVisibility {
    static func hideDashboard() {
        for window in dashboardWindows {
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        NSRunningApplication.current.hide()
    }

    static func showDashboard() {
        ActivityStore.shared.reloadFromDisk()
        NSApp.setActivationPolicy(.accessory)
        let windows = dashboardWindows
        for duplicate in windows.dropFirst() {
            duplicate.close()
        }
        if let dashboard = windows.first {
            dashboard.makeKeyAndOrderFront(nil)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private static var dashboardWindows: [NSWindow] {
        NSApp.windows
            .filter { $0.title == "LifeTracker" }
            .sorted { $0.orderedIndex < $1.orderedIndex }
    }
}
