import SwiftUI

struct MetricsGrid: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        let stats = store.stats
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                MetricCard(title: "Today", value: LTFormat.minutes(stats.todayMinutes), detail: "\(stats.activeProjectsToday) active projects", tint: AppTheme.green)
                MetricCard(title: "This week", value: LTFormat.minutes(stats.weekMinutes), detail: "\(store.selectedRangeDays)d range", tint: AppTheme.blue)
                MetricCard(title: "Sessions", value: "\(stats.sessionCount)", detail: "focused bursts", tint: AppTheme.amber)
                MetricCard(title: "File events", value: "\(stats.eventCount)", detail: "metadata only", tint: .purple)
                MetricCard(title: "Foreground", value: stats.currentApp, detail: "current app", tint: .cyan)
                MetricCard(title: "Latest", value: latestText(stats.latestActivity), detail: "saved activity", tint: .mint)
            }
        }
    }

    private func latestText(_ date: Date?) -> String {
        guard let date else {
            return "-"
        }
        return LTFormat.relative(date)
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var detail: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(CardBackground(tint: tint))
    }
}

struct CardBackground: View {
    var tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(AppTheme.panel)
            .shadow(color: tint.opacity(0.10), radius: 18, x: 0, y: 10)
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .fill(tint)
                    .frame(height: 2)
                    .opacity(0.75)
                    .padding(.horizontal, 14)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.line)
            }
    }
}
