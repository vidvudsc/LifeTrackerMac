import SwiftUI

struct MetricsGrid: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        let stats = store.rangeStats
        let bars = dailyMetricBars()

        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricSummaryCard(
                    title: "Total Time",
                    value: LTFormat.minutes(stats.totalMinutes),
                    detail: "\(signedPercent(stats.totalDelta)) vs \(comparisonLabel)",
                    tint: AppTheme.lilac,
                    points: bars.total
                )
                MetricSummaryCard(
                    title: "Focus Time",
                    value: LTFormat.minutes(stats.focusMinutes),
                    detail: "\(stats.focusShare)% of \(rangeLabel)",
                    tint: AppTheme.lilac,
                    points: bars.focus
                )
                MetricSummaryCard(
                    title: "Coding Time",
                    value: LTFormat.minutes(stats.codingMinutes),
                    detail: "\(stats.codingShare)% of \(rangeLabel)",
                    tint: AppTheme.coral,
                    points: bars.coding
                )
            }

            HStack(spacing: 10) {
                CompactMetricCard(title: "Projects", value: "\(stats.projectCount)", detail: "Active")
                CompactMetricCard(title: "Files", value: "\(stats.fileCount)", detail: "Edited")
                CompactMetricCard(title: "Sessions", value: "\(stats.sessionCount)", detail: "Completed")
                CompactMetricCard(title: "Energy", value: "\(stats.averageEnergy)", detail: "avg", showsStatusDot: true)
            }
        }
    }

    private func signedPercent(_ value: Int) -> String {
        value > 0 ? "+\(value)%" : "\(value)%"
    }

    private var comparisonLabel: String {
        switch store.selectedRangeDays {
        case 1:
            return "yesterday"
        case 7:
            return "last week"
        case 14:
            return "prior 2 weeks"
        case 30:
            return "last month"
        default:
            return "prior \(store.selectedRangeDays) days"
        }
    }

    private var rangeLabel: String {
        switch store.selectedRangeDays {
        case 1:
            return "today"
        case 7:
            return "this week"
        case 14:
            return "these 2 weeks"
        case 30:
            return "this month"
        default:
            return "this range"
        }
    }

    private func dailyMetricBars() -> (total: [MiniMetricPoint], focus: [MiniMetricPoint], coding: [MiniMetricPoint]) {
        let calendar = Calendar.current
        let count = min(max(store.selectedRangeDays, 1), 14)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -count + 1, to: today) ?? today
        let days = (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }

        var focus: [MiniMetricPoint] = []
        var coding: [MiniMetricPoint] = []
        var total: [MiniMetricPoint] = []

        for day in days {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let focusMinutes = store.topApps(from: day, to: nextDay).reduce(0) { $0 + $1.minutes }
            let codingMinutes = store.sessions(from: day, to: nextDay).reduce(0) { $0 + $1.minutes }
            focus.append(MiniMetricPoint(date: day, value: focusMinutes))
            coding.append(MiniMetricPoint(date: day, value: codingMinutes))
            total.append(MiniMetricPoint(date: day, value: focusMinutes + codingMinutes))
        }

        return (total, focus, coding)
    }
}

struct MetricSummaryCard: View {
    var title: String
    var value: String
    var detail: String
    var tint: Color
    var points: [MiniMetricPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(detail)
                .font(.caption.weight(.medium))
                .foregroundStyle(detail.hasPrefix("+") ? AppTheme.green : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            MiniBarStrip(points: points, tint: tint)
                .frame(height: 30)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(14)
        .background(DashboardCardBackground())
    }
}

struct CompactMetricCard: View {
    var title: String
    var value: String
    var detail: String
    var showsStatusDot = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if showsStatusDot {
                    Circle()
                        .fill(AppTheme.green)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(14)
        .background(DashboardCardBackground())
    }
}

struct MiniMetricPoint: Identifiable {
    var id: Date { date }
    var date: Date
    var value: Int
}

struct MiniBarStrip: View {
    var points: [MiniMetricPoint]
    var tint: Color

    var body: some View {
        let maxValue = max(points.map(\.value).max() ?? 1, 1)

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(points) { point in
                let ratio = Double(point.value) / Double(maxValue)
                let height = point.value <= 0 ? 4 : max(8, CGFloat(ratio) * 28)
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(point.value <= 0 ? AppTheme.energyQuiet : tint)
                    .frame(width: 7, height: height)
                    .help("\(LTFormat.shortDate.string(from: point.date)): \(LTFormat.minutes(point.value))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
