import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: ActivityStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            todaySummary
            hourlyStrip
            focusRows
            recentSession
            actions
        }
        .padding(14)
        .frame(width: 340)
        .background(MenuBarTheme.background)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: AppIconImage.current)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("LifeTracker")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(store.stats.currentApp)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(store.isTracking ? AppTheme.green : AppTheme.red)
                    .frame(width: 7, height: 7)
                Text(store.isTracking ? "Live" : "Paused")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(store.isTracking ? AppTheme.green : AppTheme.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background((store.isTracking ? AppTheme.green : AppTheme.red).opacity(0.12), in: Capsule())
        }
    }

    private var todaySummary: some View {
        HStack(spacing: 10) {
            MenuStatCard(
                title: "Coding",
                value: LTFormat.minutes(store.stats.todayMinutes),
                detail: "\(store.stats.activeProjectsToday) projects",
                tint: AppTheme.coral
            )
            MenuStatCard(
                title: "Focus",
                value: LTFormat.minutes(store.todayAppFocusMinutes),
                detail: store.todayTopApp?.app ?? "No app yet",
                tint: AppTheme.lilac
            )
        }
    }

    private var hourlyStrip: some View {
        MenuHourlyStrip(values: store.hourlyEnergyPoints())
    }

    private var focusRows: some View {
        VStack(spacing: 0) {
            MenuInfoRow(
                icon: "macwindow",
                title: "Top app",
                value: store.todayTopApp.map { "\($0.app) · \(LTFormat.minutes($0.minutes))" } ?? "-"
            )
            MenuDivider()
            MenuInfoRow(
                icon: "folder.fill",
                title: "Top project",
                value: store.topProjects.first.map { "\($0.project) · \(LTFormat.minutes($0.minutes))" } ?? "-"
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MenuBarTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MenuBarTheme.line)
        }
    }

    private var recentSession: some View {
        let session = store.sessions(since: Calendar.current.startOfDay(for: Date())).first

        return VStack(alignment: .leading, spacing: 8) {
            Text("Latest session")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            if let session {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.project)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text("\(LTFormat.time.string(from: session.start)) - \(LTFormat.time.string(from: session.end)) · \(session.fileCount) files")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(LTFormat.minutes(session.minutes))
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No coding session today yet.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(MenuBarTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MenuBarTheme.line)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                MenuActionButton(title: "Dashboard", systemImage: "rectangle.grid.2x2") {
                    openWindow(id: "main")
                    WindowVisibility.showDashboard()
                }

                MenuActionButton(title: store.isTracking ? "Pause" : "Start", systemImage: store.isTracking ? "pause.fill" : "play.fill") {
                    store.toggleTracking()
                }
            }

            HStack(spacing: 8) {
                MenuActionButton(title: "Hide", systemImage: "eye.slash") {
                    WindowVisibility.hideDashboard()
                }

                MenuActionButton(title: "Quit", systemImage: "power") {
                    NSApp.terminate(nil)
                }
            }
        }
    }
}

struct MenuStatCard: View {
    var title: String
    var value: String
    var detail: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(MenuBarTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 999)
                .fill(tint)
                .frame(width: 38, height: 3)
                .padding(.leading, 12)
                .padding(.bottom, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MenuBarTheme.line)
        }
    }
}

struct MenuHourlyStrip: View {
    var values: [HourlyEnergyPoint]

    @State private var hoveredHourID: Date?

    var body: some View {
        let maxScore = max(values.map(\.score).max() ?? 1, 1)
        let hoveredPoint = values.first { $0.id == hoveredHourID }

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today rhythm")
                    .font(.caption.weight(.bold))
                Spacer()
                if let hoveredPoint {
                    Text(menuHourSummary(hoveredPoint))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.lilac)
                        .lineLimit(1)
                        .monospacedDigit()
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(values) { point in
                    MenuHourBar(
                        point: point,
                        maxScore: maxScore,
                        isHovered: hoveredHourID == point.id
                    ) { isHovered in
                        let nextID = isHovered ? point.id : nil
                        if hoveredHourID != nextID {
                            hoveredHourID = nextID
                        }
                    }
                }
            }
            .frame(height: 38, alignment: .bottom)

            if let hoveredPoint {
                Text(menuHourDetail(hoveredPoint))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 12, alignment: .leading)
            } else {
                Color.clear
                    .frame(height: 12)
            }
        }
        .padding(12)
        .background(MenuBarTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MenuBarTheme.line)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func menuHourSummary(_ point: HourlyEnergyPoint) -> String {
        "\(point.hourLabel) · \(point.energyValue)"
    }

    private func menuHourDetail(_ point: HourlyEnergyPoint) -> String {
        "\(point.hourLabel) · \(LTFormat.minutes(point.minutes)) · \(point.events) events · \(point.files) files"
    }
}

struct MenuHourBar: View {
    var point: HourlyEnergyPoint
    var maxScore: Double
    var isHovered: Bool
    var onHover: (Bool) -> Void

    var body: some View {
        let ratio = point.score <= 0 ? 0 : min(1, point.score / maxScore)
        let height = point.score <= 0 ? 5 : max(8, CGFloat(ratio) * 34)

        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(point.score <= 0 ? AppTheme.energyQuiet : AppTheme.lilac)
                .frame(height: height)
                .overlay {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(AppTheme.lilac.opacity(0.95), lineWidth: 1)
                    }
                }
                .shadow(color: AppTheme.lilac.opacity(isHovered && point.score > 0 ? 0.35 : 0), radius: 5, y: 1)

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(isHovered ? AppTheme.lilac : Color.clear)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: 38, alignment: .bottom)
        .contentShape(Rectangle())
        .onHover(perform: onHover)
    }
}

struct MenuInfoRow: View {
    var icon: String
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.lilac)
                .frame(width: 20)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

struct MenuActionButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .background(MenuBarTheme.button, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(MenuBarTheme.line)
        }
    }
}

struct MenuDivider: View {
    var body: some View {
        Rectangle()
            .fill(MenuBarTheme.line)
            .frame(height: 1)
    }
}

enum MenuBarTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.055, green: 0.052, blue: 0.066),
            Color(red: 0.025, green: 0.027, blue: 0.034)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let card = Color.white.opacity(0.075)
    static let button = Color.white.opacity(0.105)
    static let line = Color.white.opacity(0.105)
}

enum AppIconImage {
    static var current: NSImage {
        let url = Bundle.module.url(forResource: "iconLife", withExtension: "png")
            ?? Bundle.main.url(forResource: "iconLife", withExtension: "png")
        return url.flatMap(NSImage.init(contentsOf:)) ?? NSImage(size: NSSize(width: 28, height: 28))
    }
}
