import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Text(rangeTitle)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                StatusPill(isTracking: store.isTracking)

                Picker("Range", selection: $store.selectedRangeDays) {
                    Text("Today").tag(1)
                    Text("This Week").tag(7)
                    Text("2 Weeks").tag(14)
                    Text("30 Days").tag(30)
                    Text("90 Days").tag(90)
                }
                .labelsHidden()
                .frame(width: 142)
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text("Here's your \(periodName) at a glance.")
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    DashboardActionButton(
                        title: store.isTracking ? "Pause" : "Start",
                        systemImage: store.isTracking ? "pause.fill" : "play.fill",
                        action: store.toggleTracking
                    )
                    DashboardActionButton(
                        title: "Hide",
                        systemImage: "eye.slash",
                        action: WindowVisibility.hideDashboard
                    )
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning."
        case 12..<18:
            return "Good afternoon."
        default:
            return "Good evening."
        }
    }

    private var periodName: String {
        switch store.selectedRangeDays {
        case 1:
            return "day"
        case 7:
            return "week"
        case 14:
            return "two weeks"
        case 30:
            return "month"
        default:
            return "\(store.selectedRangeDays) days"
        }
    }

    private var rangeTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard store.selectedRangeDays > 1 else {
            return "Today"
        }
        let start = calendar.date(byAdding: .day, value: -store.selectedRangeDays + 1, to: today) ?? today
        return "\(LTFormat.shortDate.string(from: start)) - \(LTFormat.shortDate.string(from: today))"
    }
}

struct DashboardActionButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

struct DashboardCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.105),
                        Color.white.opacity(0.060)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.055))
                    .frame(height: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.line)
            }
    }
}

struct DashboardPanel<Content: View>: View {
    var title: String
    var trailing: String?
    @ViewBuilder var content: Content

    init(title: String, trailing: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(14)
        .background(DashboardCardBackground())
    }
}

struct DashboardRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.line)
            .frame(height: 1)
    }
}

struct StatusPill: View {
    var isTracking: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isTracking ? AppTheme.green : AppTheme.red)
                .frame(width: 7, height: 7)
            Text(isTracking ? "Tracking" : "Paused")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(isTracking ? AppTheme.green : AppTheme.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isTracking ? AppTheme.green : AppTheme.red).opacity(0.12), in: Capsule())
        .overlay {
            Capsule()
                .stroke((isTracking ? AppTheme.green : AppTheme.red).opacity(0.18))
        }
    }
}
