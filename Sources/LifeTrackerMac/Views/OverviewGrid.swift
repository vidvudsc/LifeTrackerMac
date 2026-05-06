import SwiftUI

struct OverviewGrid: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Panel(title: "Energy", subtitle: "daily weighted activity") {
                EnergyChart()
                    .frame(height: 210)
            }
            .frame(maxWidth: .infinity)

            Panel(title: "Insights", subtitle: "computed locally") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.insights, id: \.self) { insight in
                        Text(insight)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .frame(width: 360)
        }
    }
}

struct EnergyChart: View {
    @EnvironmentObject private var store: ActivityStore
    @State private var hoveredDay: Date?

    var body: some View {
        let values = dailyEnergy()
        let maxScore = max(values.map(\.score).max() ?? 1, 1)

        HStack(alignment: .bottom, spacing: 7) {
            ForEach(values) { item in
                let ratio = item.score <= 0 ? 0 : sqrt(item.score) / sqrt(maxScore)
                let height = item.score <= 0 ? 8 : max(12, CGFloat(ratio) * 160)

                VStack(spacing: 5) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color)
                            .frame(height: height)
                            .help(item.helpText)
                    }
                    .frame(height: 150, alignment: .bottom)
                    .contentShape(Rectangle())
                    .onHover { isHovering in
                        withAnimation(.snappy(duration: 0.14)) {
                            hoveredDay = isHovering ? item.id : nil
                        }
                    }

                    Text(hoveredDay == item.id ? "\(item.energyValue)" : " ")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, minHeight: 10, maxHeight: 10)

                    VStack(spacing: 1) {
                        Text(item.monthLabel)
                        Text(item.dayLabel)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 28)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func dailyEnergy() -> [EnergyPoint] {
        let calendar = Calendar.current
        let dayCount = min(max(store.selectedRangeDays, 7), 30)
        let today = calendar.startOfDay(for: Date())
        let events = store.recentEvents
        let changes = store.recentContentChanges
        let activityDates = events.map(\.date) + changes.map(\.date)
        let firstActivityDay = activityDates.map { calendar.startOfDay(for: $0) }.min()
        let startDay = firstActivityDay ?? (calendar.date(byAdding: .day, value: -dayCount + 1, to: today) ?? today)
        let days = (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDay)
        }
        let sessions = store.sessions(since: startDay)

        return days.map { day in
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let dayEvents = events.filter { $0.date >= day && $0.date < nextDay }
            let dayChanges = changes.filter { $0.date >= day && $0.date < nextDay }
            let daySessions = sessions.filter { $0.start >= day && $0.start < nextDay }
            let minutes = daySessions.reduce(0) { $0 + $1.minutes }
            let files = Set(dayEvents.map(\.path)).count
            let score = Double(minutes)
                + sqrt(Double(dayEvents.count)) * 5
                + Double(files) * 2
                + Double(dayChanges.count) * 4

            return EnergyPoint(
                date: day,
                label: LTFormat.shortDate.string(from: day),
                monthLabel: LTFormat.month.string(from: day),
                dayLabel: LTFormat.day.string(from: day),
                score: score,
                minutes: minutes,
                events: dayEvents.count,
                files: files,
                changes: dayChanges.count
            )
        }
    }
}

struct EnergyPoint: Identifiable {
    var id: Date { date }
    var date: Date
    var label: String
    var monthLabel: String
    var dayLabel: String
    var score: Double
    var minutes: Int
    var events: Int
    var files: Int
    var changes: Int

    var energyValue: Int {
        Int(score.rounded())
    }

    var color: Color {
        score <= 0 ? AppTheme.energyQuiet : AppTheme.energyBar
    }

    var helpText: String {
        "\(label): \(energyValue) energy, \(LTFormat.minutes(minutes)), \(events) events, \(files) files, \(changes) content changes"
    }
}

struct Panel<Content: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Divider()
                .overlay(AppTheme.line)
            content
        }
        .padding(18)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.line)
        }
    }
}
