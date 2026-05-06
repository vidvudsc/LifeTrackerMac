import SwiftUI

struct TimelineSection: View {
    @EnvironmentObject private var store: ActivityStore
    @State private var showAllSessions = false

    var body: some View {
        DashboardPanel(title: title, trailing: "sessions split after 15 minutes idle") {
            let sessions = store.sessions(since: store.rangeStart)
            if sessions.isEmpty {
                EmptyState(text: "No file activity in this range yet.")
            } else {
                let rows = Array(sessions.prefix(showAllSessions ? 24 : 8))
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, session in
                        TimelineRow(session: session)
                        if index < rows.count - 1 {
                            DashboardRowDivider()
                        }
                    }
                }

                if sessions.count > 8 {
                    ShowAllButton(title: showAllSessions ? "Show Less Sessions" : "Show All Sessions") {
                        withAnimation(.snappy(duration: 0.18)) {
                            showAllSessions.toggle()
                        }
                    }
                }
            }
        }
    }

    private var title: String {
        store.selectedRangeDays == 1 ? "Today Timeline" : "Timeline"
    }
}

struct TimelineRow: View {
    var session: WorkSession

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LTFormat.shortDate.string(from: session.start))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                Text("\(LTFormat.time.string(from: session.start)) - \(LTFormat.time.string(from: session.end))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(width: 132, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.project)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                Text(detailText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Text(LTFormat.minutes(session.minutes))
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(AppTheme.panelStrong, in: Capsule())
        }
        .padding(.vertical, 12)
    }

    private var detailText: String {
        let extensions = session.extensions.isEmpty ? "mixed files" : session.extensions.joined(separator: ", ")
        return "\(session.fileCount) files - \(session.eventCount) events - \(extensions)"
    }
}
