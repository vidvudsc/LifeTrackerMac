import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: ActivityStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LifeTracker")
                .font(.headline)

            Text(store.stats.currentApp)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Divider()

            Button("Show Dashboard") {
                openWindow(id: "main")
                WindowVisibility.showDashboard()
            }

            Button("Hide Dashboard") {
                WindowVisibility.hideDashboard()
            }

            Button(store.isTracking ? "Stop Tracking" : "Start Tracking") {
                store.toggleTracking()
            }

            Button("Scan Now") {
                store.runScan()
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(4)
    }
}
