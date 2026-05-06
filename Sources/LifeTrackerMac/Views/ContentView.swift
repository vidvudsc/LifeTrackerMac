import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ActivityStore
    @State private var selection: SectionID? = .overview

    var body: some View {
        ScrollViewReader { proxy in
            NavigationSplitView {
                SidebarView(selection: $selection)
            } detail: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeaderView()
                        VStack(alignment: .leading, spacing: 18) {
                            MetricsGrid()
                            OverviewGrid()
                        }
                        .id(SectionID.overview)
                        TimelineSection()
                            .id(SectionID.timeline)
                        AppsSection()
                            .id(SectionID.apps)
                        ProjectsSection()
                            .id(SectionID.projects)
                    }
                    .padding(24)
                }
                .background(AppTheme.background)
                .onChange(of: selection) { _, newValue in
                    guard let newValue else {
                        return
                    }
                    scroll(to: newValue, proxy: proxy)
                }
            }
        }
    }

    private func scroll(to section: SectionID, proxy: ScrollViewProxy) {
        selection = section
        withAnimation(.snappy(duration: 0.28)) {
            proxy.scrollTo(section, anchor: .top)
        }
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
            Color(red: 0.035, green: 0.043, blue: 0.063),
            Color(red: 0.055, green: 0.071, blue: 0.102)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = Color.white.opacity(0.055)
    static let panelStrong = Color.white.opacity(0.08)
    static let panelRaised = Color.white.opacity(0.11)
    static let line = Color.white.opacity(0.10)
    static let green = Color(red: 0.36, green: 0.88, blue: 0.64)
    static let blue = Color(red: 0.43, green: 0.66, blue: 1.0)
    static let amber = Color(red: 0.95, green: 0.72, blue: 0.37)
    static let energyBar = Color(red: 0.88, green: 0.58, blue: 0.35)
    static let energyQuiet = Color.white.opacity(0.12)
    static let meterFill = Color(red: 0.78, green: 0.62, blue: 0.44)
    static let meterTrack = Color.white.opacity(0.075)
    static let red = Color(red: 1.0, green: 0.43, blue: 0.40)
}
