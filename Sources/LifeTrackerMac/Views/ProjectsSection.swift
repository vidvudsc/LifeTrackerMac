import SwiftUI

struct ProjectsSection: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        DashboardPanel(title: "Project board", trailing: "ranked by recent activity") {
            if store.topProjects.isEmpty {
                EmptyState(text: "No project activity in this range.")
            } else {
                let total = max(store.topProjects.reduce(0) { $0 + $1.minutes }, 1)
                VStack(spacing: 0) {
                    ForEach(Array(store.topProjects.prefix(14).enumerated()), id: \.element.project) { index, row in
                        TopUsageRow(
                            icon: "folder.fill",
                            title: row.project,
                            minutes: row.minutes,
                            percent: Int((Double(row.minutes) / Double(total) * 100).rounded())
                        )
                        if index < min(store.topProjects.count, 14) - 1 {
                            DashboardRowDivider()
                        }
                    }
                }
            }
        }
    }
}

struct EmptyState: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8))
    }
}
