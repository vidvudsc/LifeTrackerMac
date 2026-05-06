import AppKit
import SwiftUI

@main
struct LifeTrackerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ActivityStore.shared

    var body: some Scene {
        WindowGroup("LifeTracker", id: "main") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1040, minHeight: 680)
                .task {
                    store.start()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(store.isTracking ? "Stop Tracking" : "Start Tracking") {
                    store.toggleTracking()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
                .frame(width: 520)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let showNotification = Notification.Name("com.vidvuds.lifetracker.showDashboard")

    func applicationWillFinishLaunching(_ notification: Notification) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.vidvuds.lifetracker"
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let existing = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .first { $0.processIdentifier != currentPID }

        if existing != nil {
            DistributedNotificationCenter.default().post(name: showNotification, object: nil)
            NSApp.terminate(nil)
            return
        }

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showDashboardFromExternalLaunch),
            name: showNotification,
            object: nil
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppIcon.install()
        ActivityStore.shared.reloadFromDisk()
        ActivityStore.shared.start()
        statusBarController = StatusBarController()
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        ActivityStore.shared.flushToDisk()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowVisibility.showDashboard()
        return true
    }

    @MainActor
    @objc private func showDashboardFromExternalLaunch() {
        ActivityStore.shared.reloadFromDisk()
        WindowVisibility.showDashboard()
    }
}
