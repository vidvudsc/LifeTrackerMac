import SwiftUI

struct ProjectsSection: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        Panel(title: "Project board", subtitle: "ranked by recent activity") {
            if store.topProjects.isEmpty {
                EmptyState(text: "No project activity in this range.")
            } else {
                VStack(spacing: 8) {
                    ForEach(store.topProjects.prefix(14), id: \.project) { row in
                        MeterRow(
                            title: row.project,
                            detail: "\(row.events) events",
                            value: row.minutes,
                            maxValue: store.topProjects.first?.minutes ?? 1
                        )
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
