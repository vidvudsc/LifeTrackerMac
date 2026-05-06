import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HeaderView()
                MetricsGrid()
                OverviewGrid()
                AppsSection()
                TimelineSection()
            }
            .padding(22)
            .frame(maxWidth: 1180, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

enum SectionID: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case timeline = "Timeline"
    case apps = "Apps"
    case projects = "Projects"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .overview: "chart.xyaxis.line"
        case .timeline: "timeline.selection"
        case .apps: "macwindow"
        case .projects: "folder"
        }
    }
}

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.055, green: 0.052, blue: 0.066),
            Color(red: 0.025, green: 0.027, blue: 0.034)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = Color.white.opacity(0.075)
    static let panelStrong = Color.white.opacity(0.105)
    static let panelRaised = Color.white.opacity(0.130)
    static let line = Color.white.opacity(0.105)
    static let green = Color(red: 0.36, green: 0.88, blue: 0.64)
    static let amber = Color(red: 0.98, green: 0.67, blue: 0.34)
    static let coral = Color(red: 0.90, green: 0.42, blue: 0.48)
    static let lilac = Color(red: 0.78, green: 0.58, blue: 0.88)
    static let energyBar = Color(red: 0.78, green: 0.58, blue: 0.88)
    static let energyQuiet = Color.white.opacity(0.080)
    static let meterFill = Color(red: 0.78, green: 0.58, blue: 0.88)
    static let meterTrack = Color.white.opacity(0.075)
    static let red = Color(red: 1.0, green: 0.43, blue: 0.40)
}
