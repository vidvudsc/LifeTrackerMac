import AppKit
import Carbon.HIToolbox

@MainActor
enum WindowVisibility {
    static func hideDashboard() {
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.orderOut(nil)
        }
        NSApp.hide(nil)
        NSRunningApplication.current.hide()
        transformProcess(to: ProcessApplicationTransformState(kProcessTransformToUIElementApplication))
        NSApp.setActivationPolicy(.accessory)
    }

    static func showDashboard() {
        ActivityStore.shared.reloadFromDisk()
        transformProcess(to: ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
        NSApp.setActivationPolicy(.regular)
        for window in NSApp.windows where window.title.contains("LifeTracker") {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func transformProcess(to state: ProcessApplicationTransformState) {
        var process = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&process, state)
    }
}
