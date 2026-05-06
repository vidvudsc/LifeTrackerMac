import SwiftUI

struct AppsSection: View {
    @EnvironmentObject private var store: ActivityStore
    @State private var showAllApps = false
    @State private var showAllProjects = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            DashboardPanel(title: "Top Apps") {
                UsageTableHeader()
                if store.topApps.isEmpty {
                    EmptyState(text: "No app samples yet.")
                } else {
                    let rows = Array(store.topApps.prefix(showAllApps ? 20 : 5))
                    let total = max(store.topApps.reduce(0) { $0 + $1.minutes }, 1)
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.app) { index, row in
                            TopUsageRow(
                                icon: appIcon(row.app),
                                title: row.app,
                                minutes: row.minutes,
                                percent: Int((Double(row.minutes) / Double(total) * 100).rounded())
                            )
                            if index < rows.count - 1 {
                                DashboardRowDivider()
                            }
                        }
                    }
                }
                if store.topApps.count > 5 {
                    ShowAllButton(title: showAllApps ? "Show Less Apps" : "Show All Apps") {
                        withAnimation(.snappy(duration: 0.18)) {
                            showAllApps.toggle()
                        }
                    }
                }
            }

            DashboardPanel(title: "Top Projects") {
                UsageTableHeader()
                if store.topProjects.isEmpty {
                    EmptyState(text: "No project activity in this range.")
                } else {
                    let rows = Array(store.topProjects.prefix(showAllProjects ? 20 : 5))
                    let total = max(store.topProjects.reduce(0) { $0 + $1.minutes }, 1)
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.project) { index, row in
                            TopUsageRow(
                                icon: "folder.fill",
                                title: row.project,
                                minutes: row.minutes,
                                percent: Int((Double(row.minutes) / Double(total) * 100).rounded())
                            )
                            if index < rows.count - 1 {
                                DashboardRowDivider()
                            }
                        }
                    }
                }
                if store.topProjects.count > 5 {
                    ShowAllButton(title: showAllProjects ? "Show Less Projects" : "Show All Projects") {
                        withAnimation(.snappy(duration: 0.18)) {
                            showAllProjects.toggle()
                        }
                    }
                }
            }
        }
    }

    private func appIcon(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("xcode") {
            return "hammer.fill"
        }
        if lower.contains("code") || lower.contains("cursor") {
            return "chevron.left.forwardslash.chevron.right"
        }
        if lower.contains("finder") {
            return "face.smiling.fill"
        }
        if lower.contains("notes") {
            return "note.text"
        }
        if lower.contains("safari") || lower.contains("chrome") || lower.contains("arc") {
            return "globe"
        }
        return "app.fill"
    }
}

struct ShowAllButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: title.contains("Less") ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}

struct UsageTableHeader: View {
    var body: some View {
        HStack {
            Text("")
                .frame(width: 20)
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Time")
                .frame(width: 72, alignment: .trailing)
            Text("%")
                .frame(width: 38, alignment: .trailing)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.secondary)
    }
}

struct TopUsageRow: View {
    var icon: String
    var title: String
    var minutes: Int
    var percent: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.lilac)
                .frame(width: 20, height: 20)
                .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 5, style: .continuous))

            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LTFormat.minutes(minutes))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 72, alignment: .trailing)

            Text("\(percent)%")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.vertical, 10)
    }
}
