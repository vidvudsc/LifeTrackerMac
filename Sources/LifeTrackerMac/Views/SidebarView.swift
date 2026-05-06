import SwiftUI

struct SidebarView: View {
    @Binding var selection: SectionID?
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(SectionID.allCases) { item in
                    Label(item.rawValue, systemImage: item.systemImage)
                        .tag(item)
                }
            }

            Section("Tracker") {
                HStack {
                    Image(systemName: store.isTracking ? "record.circle.fill" : "pause.circle")
                        .foregroundStyle(store.isTracking ? AppTheme.green : .secondary)
                    Text(store.isTracking ? "Running" : "Paused")
                    Spacer()
                    if store.isScanning {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Button(store.isTracking ? "Stop Tracking" : "Start Tracking") {
                    store.toggleTracking()
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("LifeTracker")
    }
}
