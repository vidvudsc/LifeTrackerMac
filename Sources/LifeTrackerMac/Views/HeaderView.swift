import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    StatusPill(isTracking: store.isTracking)
                    Text("Local only")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.panelStrong, in: Capsule())
                }

                Text("LifeTracker")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(store.watchRoots.map(\.path).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                Picker("Range", selection: $store.selectedRangeDays) {
                    Text("7d").tag(7)
                    Text("14d").tag(14)
                    Text("30d").tag(30)
                    Text("90d").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                HStack(spacing: 10) {
                    Button {
                        store.toggleTracking()
                    } label: {
                        Label(store.isTracking ? "Stop" : "Start", systemImage: store.isTracking ? "pause.fill" : "play.fill")
                    }

                    Button {
                        store.runScan()
                    } label: {
                        Label("Check", systemImage: "waveform.path.ecg")
                    }

                    Button {
                        WindowVisibility.hideDashboard()
                    } label: {
                        Label("Hide", systemImage: "eye.slash")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.line)
        }
    }
}

struct StatusPill: View {
    var isTracking: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isTracking ? AppTheme.green : AppTheme.red)
                .frame(width: 7, height: 7)
            Text(isTracking ? "Tracking" : "Paused")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(isTracking ? AppTheme.green : AppTheme.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isTracking ? AppTheme.green : AppTheme.red).opacity(0.12), in: Capsule())
    }
}
