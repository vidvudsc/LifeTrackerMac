import SwiftUI

struct TimelineSection: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        Panel(title: "Today timeline", subtitle: "sessions split after 15 minutes idle") {
            let sessions = store.sessions(since: Calendar.current.startOfDay(for: Date()))
            if sessions.isEmpty {
                EmptyState(text: "No file activity today yet.")
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions.prefix(12)) { session in
                        HStack(spacing: 14) {
                            Text("\(LTFormat.time.string(from: session.start)) - \(LTFormat.time.string(from: session.end))")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 130, alignment: .leading)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.project)
                                    .font(.callout.weight(.semibold))
                                Text("\(session.fileCount) files · \(session.eventCount) events · \(session.extensions.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(LTFormat.minutes(session.minutes))
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(AppTheme.panelStrong, in: Capsule())
                        }
                        .padding(12)
                        .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}
