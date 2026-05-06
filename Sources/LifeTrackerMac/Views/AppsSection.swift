import SwiftUI

struct AppsSection: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Panel(title: "Foreground apps", subtitle: "screen focus") {
                if store.topApps.isEmpty {
                    EmptyState(text: "No app samples yet.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.topApps.prefix(10), id: \.app) { row in
                            MeterRow(title: row.app, detail: "foreground", value: row.minutes, maxValue: store.topApps.first?.minutes ?? 1)
                        }
                    }
                }
            }

            Panel(title: "Recent switches", subtitle: "app name only") {
                if store.recentAppSamples.isEmpty {
                    EmptyState(text: "No app switches recorded yet.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.recentAppSamples.prefix(10)) { sample in
                            HStack {
                                Text(LTFormat.time.string(from: sample.date))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 62, alignment: .leading)
                                Text(sample.appName)
                                    .font(.callout.weight(.semibold))
                                Spacer()
                            }
                            .padding(10)
                            .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }
}

struct MeterRow: View {
    var title: String
    var detail: String
    var value: Int
    var maxValue: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(LTFormat.minutes(value))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.meterTrack)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(AppTheme.meterFill)
                            .frame(width: proxy.size.width * CGFloat(value) / CGFloat(max(maxValue, 1)))
                    }
            }
            .frame(height: 7)
        }
        .padding(12)
        .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8))
    }
}
