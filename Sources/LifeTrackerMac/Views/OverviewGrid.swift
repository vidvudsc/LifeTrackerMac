import SwiftUI

struct OverviewGrid: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardPanel(title: energyTitle) {
                EnergyChart()
                    .frame(height: 250)
            }

            InsightsSection()
        }
    }

    private var energyTitle: String {
        switch store.selectedRangeDays {
        case 1:
            return "Today Energy by Hour"
        case 7:
            return "Weekly Energy"
        case 30:
            return "Monthly Energy"
        default:
            return "Range Energy"
        }
    }
}

struct EnergyChart: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        if store.selectedRangeDays == 1 {
            HourlyEnergyChart()
        } else {
            DailyEnergyChart()
        }
    }
}

struct DailyEnergyChart: View {
    @EnvironmentObject private var store: ActivityStore
    @State private var hoveredDay: Date?

    var body: some View {
        let values = store.dailyEnergyPoints(dayCount: store.selectedRangeDays)
        let maxScore = max(values.map(\.score).max() ?? 100, 100)

        EnergyChartFrame {
            HStack(alignment: .bottom, spacing: 15) {
                ForEach(values) { item in
                    EnergyBarColumn(
                        item: item,
                        maxScore: maxScore,
                        isHovered: hoveredDay == item.id
                    ) { isHovering in
                        withAnimation(.snappy(duration: 0.14)) {
                            hoveredDay = isHovering ? item.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        } labels: {
            HStack(alignment: .top, spacing: 15) {
                ForEach(values) { item in
                    VStack(spacing: 3) {
                        Text(hoveredDay == item.id && item.energyValue > 0 ? "\(item.energyValue)" : "")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(height: 10)

                        Text(item.monthLabel)
                            .font(.caption2.weight(.semibold))
                        Text(item.dayLabel)
                            .font(.caption2.weight(.medium))
                        Text(item.minutes > 0 ? LTFormat.minutes(item.minutes) : "-")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct HourlyEnergyChart: View {
    @EnvironmentObject private var store: ActivityStore
    @State private var hoveredHour: Date?

    var body: some View {
        let values = store.hourlyEnergyPoints()
        let maxScore = max(values.map(\.score).max() ?? 100, 100)

        EnergyChartFrame {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(values.enumerated()), id: \.element.id) { _, item in
                    HourlyEnergyBarColumn(
                        item: item,
                        maxScore: maxScore,
                        isHovered: hoveredHour == item.id
                    ) { isHovering in
                        withAnimation(.snappy(duration: 0.14)) {
                            hoveredHour = isHovering ? item.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        } labels: {
            HStack(alignment: .top, spacing: 5) {
                ForEach(Array(values.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 3) {
                        Text(hoveredHour == item.id && item.energyValue > 0 ? "\(item.energyValue)" : "")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(height: 10)

                        Text(index % 3 == 0 ? compactHour(item.hourLabel) : "")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Text(item.minutes > 0 ? LTFormat.minutes(item.minutes) : "")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func compactHour(_ value: String) -> String {
        value.replacingOccurrences(of: "AM", with: "a")
            .replacingOccurrences(of: "PM", with: "p")
    }
}

struct EnergyChartFrame<Bars: View, Labels: View>: View {
    @ViewBuilder var bars: Bars
    @ViewBuilder var labels: Labels

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("100")
                Spacer()
                Text("50")
                Spacer()
                Text("0")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 150)
            .padding(.top, 14)

            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    EnergyGridLines()
                    bars
                }
                .frame(height: 164)

                labels
            }
        }
    }
}

struct EnergyGridLines: View {
    var body: some View {
        VStack {
            gridLine
            Spacer()
            gridLine
            Spacer()
            gridLine
        }
    }

    private var gridLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.055))
            .frame(height: 1)
    }
}

struct EnergyBarColumn: View {
    var item: DailyEnergyPoint
    var maxScore: Double
    var isHovered: Bool
    var onHover: (Bool) -> Void

    var body: some View {
        EnergyBarShell(
            score: item.score,
            maxScore: maxScore,
            isHovered: isHovered,
            helpText: item.helpText,
            onHover: onHover
        )
    }
}

struct HourlyEnergyBarColumn: View {
    var item: HourlyEnergyPoint
    var maxScore: Double
    var isHovered: Bool
    var onHover: (Bool) -> Void

    var body: some View {
        EnergyBarShell(
            score: item.score,
            maxScore: maxScore,
            isHovered: isHovered,
            helpText: item.helpText,
            onHover: onHover
        )
    }
}

struct EnergyBarShell: View {
    var score: Double
    var maxScore: Double
    var isHovered: Bool
    var helpText: String
    var onHover: (Bool) -> Void

    var body: some View {
        let ratio = score <= 0 ? 0 : min(1, score / maxScore)
        let height = score <= 0 ? 0 : max(18, CGFloat(ratio) * 144)

        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(AppTheme.line, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(0.030))
                )
                .frame(height: 144)

            if score > 0 {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.86, green: 0.68, blue: 0.98),
                                AppTheme.lilac.opacity(0.90)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height)
                    .shadow(color: AppTheme.lilac.opacity(isHovered ? 0.30 : 0.15), radius: isHovered ? 8 : 4, y: 2)
                    .help(helpText)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onHover(perform: onHover)
    }
}

struct InsightsSection: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        DashboardPanel(title: "Insights", trailing: "computed locally") {
            let insights = store.dashboardInsights
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }
}

struct InsightCard: View {
    var insight: DashboardInsight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.lilac)
                .frame(width: 24, height: 24)
                .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(insight.value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(insight.detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .padding(12)
        .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.line)
        }
    }
}

struct Panel<Content: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        DashboardPanel(title: title, trailing: subtitle) {
            content
        }
    }
}
