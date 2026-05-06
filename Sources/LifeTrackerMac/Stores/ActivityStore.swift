import AppKit
import Foundation

@MainActor
final class ActivityStore: ObservableObject {
    static let shared = ActivityStore()

    @Published private(set) var archive = ActivityArchive()
    @Published private(set) var isTracking = false
    @Published private(set) var isScanning = false
    @Published private(set) var lastSavedAt: Date?
    @Published var selectedRangeDays = 14

    let watchRoots: [URL] = [
        URL(fileURLWithPath: "/Users/vidvudscalitis/Desktop/CODING", isDirectory: true)
    ]

    private var appTimer: Timer?
    private var fileMonitor: FileSystemEventMonitor?
    private var pendingSaveTask: Task<Void, Never>?
    private var lastAppName = ""
    private var lastAppHeartbeat = Date.distantPast
    private let appInterval: TimeInterval = 15

    init() {
        load()
    }

    var stats: DashboardStats {
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
        let todaySessions = sessions(since: todayStart)
        let weekSessions = sessions(since: weekStart)
        return DashboardStats(
            todayMinutes: todaySessions.reduce(0) { $0 + $1.minutes },
            weekMinutes: weekSessions.reduce(0) { $0 + $1.minutes },
            sessionCount: sessions(since: rangeStart).count,
            eventCount: recentEvents.count,
            activeProjectsToday: Set(todaySessions.map(\.project)).count,
            currentApp: latestUserFacingAppName ?? "-",
            latestActivity: latestActivityDate,
            savedAt: lastSavedAt
        )
    }

    var latestActivityDate: Date? {
        let latestFile = archive.events.map(\.date).max()
        let latestApp = archive.appSamples.map(\.date).max()
        switch (latestFile, latestApp) {
        case let (file?, app?):
            return max(file, app)
        case let (file?, nil):
            return file
        case let (nil, app?):
            return app
        case (nil, nil):
            return nil
        }
    }

    var rangeStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -max(selectedRangeDays, 1) + 1, to: today) ?? today
    }

    var recentEvents: [FileActivityEvent] {
        archive.events.filter { $0.date >= rangeStart }.sorted { $0.date > $1.date }
    }

    var recentContentChanges: [FileChangeSummary] {
        archive.contentChanges.filter { $0.date >= rangeStart }.sorted { $0.date > $1.date }
    }

    var recentAppSamples: [AppFocusSample] {
        archive.appSamples
            .filter { $0.date >= rangeStart && isUserFacingAppName($0.appName) }
            .sorted { $0.date > $1.date }
    }

    var topProjects: [(project: String, minutes: Int, events: Int)] {
        let grouped = Dictionary(grouping: sessions(since: rangeStart), by: \.project)
        return grouped.map { key, value in
            (key, value.reduce(0) { $0 + $1.minutes }, value.reduce(0) { $0 + $1.eventCount })
        }
        .sorted { lhs, rhs in
            lhs.minutes == rhs.minutes ? lhs.events > rhs.events : lhs.minutes > rhs.minutes
        }
    }

    var topApps: [(app: String, minutes: Int)] {
        topApps(from: rangeStart)
    }

    var rangeStats: DashboardRangeStats {
        let calendar = Calendar.current
        let dayCount = max(selectedRangeDays, 1)
        let currentStart = rangeStart
        let previousStart = calendar.date(byAdding: .day, value: -dayCount, to: currentStart) ?? currentStart
        let now = Date()
        let currentSessions = sessions(from: currentStart, to: now)
        let previousSessions = sessions(from: previousStart, to: currentStart)
        let focusMinutes = topApps(from: currentStart, to: now).reduce(0) { $0 + $1.minutes }
        let previousFocusMinutes = topApps(from: previousStart, to: currentStart).reduce(0) { $0 + $1.minutes }
        let codingMinutes = currentSessions.reduce(0) { $0 + $1.minutes }
        let previousCodingMinutes = previousSessions.reduce(0) { $0 + $1.minutes }
        let energyValues = dailyEnergyPoints(dayCount: dayCount).filter { $0.date <= now }.map(\.energyValue)

        return DashboardRangeStats(
            totalMinutes: focusMinutes + codingMinutes,
            focusMinutes: focusMinutes,
            codingMinutes: codingMinutes,
            previousTotalMinutes: previousFocusMinutes + previousCodingMinutes,
            previousFocusMinutes: previousFocusMinutes,
            previousCodingMinutes: previousCodingMinutes,
            projectCount: Set(currentSessions.map(\.project)).count,
            fileCount: Set(recentEvents.map(\.path)).count,
            sessionCount: currentSessions.count,
            averageEnergy: energyValues.isEmpty ? 0 : Int((Double(energyValues.reduce(0, +)) / Double(energyValues.count)).rounded())
        )
    }

    var todayAppFocusMinutes: Int {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return topApps(from: todayStart).reduce(0) { $0 + $1.minutes }
    }

    var todayTopApp: (app: String, minutes: Int)? {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return topApps(from: todayStart).first
    }

    func topApps(since startDate: Date) -> [(app: String, minutes: Int)] {
        topApps(from: startDate)
    }

    func topApps(from startDate: Date, to endDate: Date = Date()) -> [(app: String, minutes: Int)] {
        var totals: [String: TimeInterval] = [:]
        let samples = archive.appSamples
            .filter { $0.date >= startDate && $0.date < endDate && isUserFacingAppName($0.appName) }
            .sorted { $0.date < $1.date }
        for index in samples.indices {
            let current = samples[index]
            let nextDate = min(index + 1 < samples.count ? samples[index + 1].date : endDate, endDate)
            let duration = min(max(nextDate.timeIntervalSince(current.date), 0), 120)
            totals[current.appName, default: 0] += duration
        }
        return totals.map { ($0.key, max(1, Int(($0.value / 60).rounded()))) }
            .sorted { $0.minutes > $1.minutes }
    }

    var insights: [String] {
        let currentSessions = sessions(since: rangeStart)
        guard !currentSessions.isEmpty else {
            return ["No activity yet. Start tracking and the dashboard will fill in from local metadata."]
        }
        let longest = currentSessions.max { $0.minutes < $1.minutes }
        let peakHour = Dictionary(grouping: currentSessions) { Calendar.current.component(.hour, from: $0.start) }
            .max { $0.value.count < $1.value.count }?.key
        var output: [String] = []
        if let longest {
            output.append("Longest burst: \(longest.project), \(LTFormat.minutes(longest.minutes)), \(longest.eventCount) file events.")
        }
        if let peakHour {
            output.append("Peak rhythm clusters around \(String(format: "%02d", peakHour)):00.")
        }
        if let top = topProjects.first {
            output.append("Most active project in range: \(top.project), \(LTFormat.minutes(top.minutes)).")
        }
        if let app = topApps.first {
            output.append("Most foreground time: \(app.app), about \(LTFormat.minutes(app.minutes)).")
        }
        return output
    }

    var dashboardInsights: [DashboardInsight] {
        let currentSessions = sessions(since: rangeStart)
        let stats = rangeStats
        guard !currentSessions.isEmpty || stats.focusMinutes > 0 else {
            return [
                DashboardInsight(
                    systemImage: "moon.zzz.fill",
                    title: "Quiet range",
                    value: "No activity yet",
                    detail: "Once tracking sees app focus or file activity, this panel will summarize the shape of the day."
                )
            ]
        }

        let calendar = Calendar.current
        let longest = currentSessions.max { $0.minutes < $1.minutes }
        let peakHour = Dictionary(grouping: currentSessions) { calendar.component(.hour, from: $0.start) }
            .max { lhs, rhs in
                let lhsMinutes = lhs.value.reduce(0) { $0 + $1.minutes }
                let rhsMinutes = rhs.value.reduce(0) { $0 + $1.minutes }
                return lhsMinutes < rhsMinutes
            }?.key
        let averageSession = currentSessions.isEmpty ? 0 : stats.codingMinutes / max(currentSessions.count, 1)
        let activeDays = Set(currentSessions.map { calendar.startOfDay(for: $0.start) }).count
        let dayName = selectedRangeDays == 1 ? "today" : "this range"
        var output: [DashboardInsight] = []

        if let topProject = topProjects.first {
            let share = stats.codingMinutes > 0 ? Int((Double(topProject.minutes) / Double(stats.codingMinutes) * 100).rounded()) : 0
            output.append(
                DashboardInsight(
                    systemImage: "folder.fill",
                    title: "Main project",
                    value: topProject.project,
                    detail: "\(LTFormat.minutes(topProject.minutes)) of coding time, about \(share)% of \(dayName)."
                )
            )
        }

        if let topApp = topApps.first {
            let share = stats.focusMinutes > 0 ? Int((Double(topApp.minutes) / Double(stats.focusMinutes) * 100).rounded()) : 0
            output.append(
                DashboardInsight(
                    systemImage: "macwindow",
                    title: "Main focus",
                    value: topApp.app,
                    detail: "\(LTFormat.minutes(topApp.minutes)) foreground, about \(share)% of focus time."
                )
            )
        }

        if let peakHour {
            let labelDate = calendar.date(bySettingHour: peakHour, minute: 0, second: 0, of: Date()) ?? Date()
            output.append(
                DashboardInsight(
                    systemImage: "clock.fill",
                    title: "Peak rhythm",
                    value: LTFormat.hour.string(from: labelDate),
                    detail: "Coding sessions cluster most strongly around this hour."
                )
            )
        }

        if let longest {
            output.append(
                DashboardInsight(
                    systemImage: "bolt.fill",
                    title: "Longest burst",
                    value: LTFormat.minutes(longest.minutes),
                    detail: "\(longest.project), \(longest.fileCount) files, \(longest.eventCount) events."
                )
            )
        }

        output.append(
            DashboardInsight(
                systemImage: "chart.bar.fill",
                title: "Session shape",
                value: averageSession > 0 ? LTFormat.minutes(averageSession) : "-",
                detail: "Average coding session length across \(currentSessions.count) sessions."
            )
        )

        if selectedRangeDays > 1 {
            output.append(
                DashboardInsight(
                    systemImage: "calendar",
                    title: "Active days",
                    value: "\(activeDays)/\(selectedRangeDays)",
                    detail: "Days with at least one file-activity coding session."
                )
            )
        }

        output.append(
            DashboardInsight(
                systemImage: "scale.3d",
                title: "Focus balance",
                value: "\(stats.focusShare)% / \(stats.codingShare)%",
                detail: "Foreground focus versus inferred coding time in \(dayName)."
            )
        )

        return Array(output.prefix(6))
    }

    func start() {
        guard !isTracking else {
            return
        }
        isTracking = true
        sampleForegroundApp()
        startFileMonitor()

        appTimer = Timer.scheduledTimer(withTimeInterval: appInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleForegroundApp()
            }
        }
    }

    func stop() {
        isTracking = false
        appTimer?.invalidate()
        fileMonitor?.stop()
        appTimer = nil
        fileMonitor = nil
        saveNow()
    }

    func toggleTracking() {
        isTracking ? stop() : start()
    }

    func runScan() {
        isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isScanning = false
        }
    }

    func sessions(since startDate: Date) -> [WorkSession] {
        sessions(from: startDate, to: Date())
    }

    func sessions(from startDate: Date, to endDate: Date = Date()) -> [WorkSession] {
        let rows = archive.events.filter { $0.date >= startDate && $0.date < endDate }.sorted { $0.date < $1.date }
        let grouped = Dictionary(grouping: rows, by: \.project)
        var output: [WorkSession] = []

        for (project, events) in grouped {
            var current: [FileActivityEvent] = []
            for event in events {
                if let last = current.last, event.date.timeIntervalSince(last.date) > 15 * 60 {
                    output.append(session(project: project, events: current))
                    current.removeAll()
                }
                current.append(event)
            }
            if !current.isEmpty {
                output.append(session(project: project, events: current))
            }
        }

        return output.sorted { $0.start > $1.start }
    }

    func dailyEnergyPoints(dayCount requestedDayCount: Int? = nil) -> [DailyEnergyPoint] {
        let calendar = Calendar.current
        let dayCount = min(max(requestedDayCount ?? selectedRangeDays, 1), 30)
        let today = calendar.startOfDay(for: Date())
        let defaultStart = calendar.date(byAdding: .day, value: -dayCount + 1, to: today) ?? today
        let events = archive.events.sorted { $0.date > $1.date }
        let changes = archive.contentChanges.sorted { $0.date > $1.date }
        let activityDates = events.map(\.date) + changes.map(\.date)
        let activeDaysInRange = activityDates
            .map { calendar.startOfDay(for: $0) }
            .filter { $0 >= defaultStart && $0 <= today }
        let startDay = activeDaysInRange.min() ?? defaultStart
        let days = (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDay)
        }
        let sessions = sessions(from: startDay, to: calendar.date(byAdding: .day, value: dayCount, to: startDay) ?? Date())

        return days.map { day in
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let dayEvents = events.filter { $0.date >= day && $0.date < nextDay }
            let dayChanges = changes.filter { $0.date >= day && $0.date < nextDay }
            let daySessions = sessions.filter { $0.start >= day && $0.start < nextDay }
            let minutes = daySessions.reduce(0) { $0 + $1.minutes }
            let files = Set(dayEvents.map(\.path)).count
            let score = Double(minutes)
                + sqrt(Double(dayEvents.count)) * 5
                + Double(files) * 2
                + Double(dayChanges.count) * 4

            return DailyEnergyPoint(
                date: day,
                label: LTFormat.shortDate.string(from: day),
                monthLabel: LTFormat.month.string(from: day),
                dayLabel: LTFormat.day.string(from: day),
                score: score,
                minutes: minutes,
                events: dayEvents.count,
                files: files,
                changes: dayChanges.count
            )
        }
    }

    func hourlyEnergyPoints(for day: Date = Date()) -> [HourlyEnergyPoint] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        let events = archive.events.sorted { $0.date > $1.date }
        let changes = archive.contentChanges.sorted { $0.date > $1.date }
        let sessions = sessions(from: dayStart, to: calendar.date(byAdding: .day, value: 1, to: dayStart) ?? Date())

        return (0..<24).compactMap { offset in
            guard let hour = calendar.date(byAdding: .hour, value: offset, to: dayStart),
                  let nextHour = calendar.date(byAdding: .hour, value: 1, to: hour) else {
                return nil
            }
            let hourEvents = events.filter { $0.date >= hour && $0.date < nextHour }
            let hourChanges = changes.filter { $0.date >= hour && $0.date < nextHour }
            let hourSessions = sessions.filter { $0.start >= hour && $0.start < nextHour }
            let minutes = hourSessions.reduce(0) { $0 + $1.minutes }
            let files = Set(hourEvents.map(\.path)).count
            let score = Double(minutes)
                + sqrt(Double(hourEvents.count)) * 5
                + Double(files) * 2
                + Double(hourChanges.count) * 4

            return HourlyEnergyPoint(
                date: hour,
                hourLabel: LTFormat.hour.string(from: hour),
                score: score,
                minutes: minutes,
                events: hourEvents.count,
                files: files,
                changes: hourChanges.count
            )
        }
    }

    private func session(project: String, events: [FileActivityEvent]) -> WorkSession {
        let fileCount = Set(events.map(\.path)).count
        let extensions = Dictionary(grouping: events, by: \.ext)
            .sorted { $0.value.count > $1.value.count }
            .prefix(4)
            .map(\.key)
        return WorkSession(
            project: project,
            start: events.first?.date ?? Date(),
            end: events.last?.date ?? Date(),
            eventCount: events.count,
            fileCount: fileCount,
            extensions: extensions
        )
    }

    private func sampleForegroundApp() {
        let name = ForegroundAppTracker.currentAppName()
        guard isUserFacingAppName(name) else {
            return
        }
        let now = Date()
        let changed = name != lastAppName
        let heartbeatDue = now.timeIntervalSince(lastAppHeartbeat) >= 60
        guard changed || heartbeatDue else {
            return
        }
        archive.appSamples.append(AppFocusSample(id: UUID(), date: now, appName: name))
        lastAppName = name
        lastAppHeartbeat = now
        trimArchive()
        scheduleSave()
    }

    private func startFileMonitor() {
        let monitor = FileSystemEventMonitor(roots: watchRoots) { [weak self] changes in
            Task { @MainActor in
                self?.recordFileChanges(changes)
            }
        }
        fileMonitor = monitor
        monitor.start()
    }

    private func recordFileChanges(_ changes: [FileSystemChange]) {
        var newEventsByPath: [String: FileActivityEvent] = [:]
        let now = Date()
        for change in changes {
            guard let event = fileEvent(from: change, date: now) else {
                continue
            }
            newEventsByPath[event.path] = event
            recordContentChange(for: event, date: now)
        }
        let newEvents = Array(newEventsByPath.values)
        guard !newEvents.isEmpty else {
            return
        }
        archive.events.append(contentsOf: newEvents)
        trimArchive()
        scheduleSave()
    }

    private func fileEvent(from change: FileSystemChange, date: Date) -> FileActivityEvent? {
        let url = URL(fileURLWithPath: change.path)
        guard let root = watchRoots.first(where: { change.path.hasPrefix($0.path) }) else {
            return nil
        }
        guard !IgnoreRules.shouldIgnore(url, root: root) else {
            return nil
        }

        let isDirectory = (change.flags & UInt32(kFSEventStreamEventFlagItemIsDir)) != 0
        guard !isDirectory else {
            return nil
        }

        let removed = (change.flags & UInt32(kFSEventStreamEventFlagItemRemoved)) != 0
        let created = (change.flags & UInt32(kFSEventStreamEventFlagItemCreated)) != 0
        let type: FileActivityEvent.EventType
        if removed {
            type = .deleted
        } else if created {
            type = .created
        } else {
            type = .modified
        }

        let size = (try? FileManager.default.attributesOfItem(atPath: change.path)[.size] as? NSNumber)?.int64Value ?? 0
        return FileActivityEvent(
            id: UUID(),
            date: date,
            type: type,
            path: change.path,
            project: IgnoreRules.projectName(for: url, root: root),
            ext: url.pathExtension.isEmpty ? "[none]" : ".\(url.pathExtension.lowercased())",
            size: size
        )
    }

    private func recordContentChange(for event: FileActivityEvent, date: Date) {
        if event.type == .deleted {
            archive.contentSnapshots.removeValue(forKey: event.path)
            return
        }
        let url = URL(fileURLWithPath: event.path)
        let previous = archive.contentSnapshots[event.path]
        let result = FileContentAnalyzer.analyze(
            url: url,
            project: event.project,
            ext: event.ext,
            previous: previous,
            date: date
        )
        if let snapshot = result.0 {
            archive.contentSnapshots[event.path] = snapshot
        }
        if let change = result.1 {
            archive.contentChanges.append(change)
        }
    }

    private func trimArchive() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -120, to: Date()) ?? Date.distantPast
        archive.events.removeAll { $0.date < cutoff }
        archive.appSamples.removeAll { $0.date < cutoff }
        archive.contentChanges.removeAll { $0.date < cutoff }
    }

    private var archiveURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = base.appendingPathComponent("LifeTrackerMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("activity.json")
    }

    func reloadFromDisk() {
        load()
    }

    func flushToDisk() {
        saveNow()
    }

    private func load() {
        guard let data = try? Data(contentsOf: archiveURL),
              let decoded = try? JSONDecoder.lifeTracker.decode(ActivityArchive.self, from: data) else {
            return
        }
        archive = decoded
        archive.events = archive.events.filter { $0.path.hasPrefix("/Users/vidvudscalitis/Desktop/CODING") }
        lastAppName = archive.appSamples.last?.appName ?? ""
        lastAppHeartbeat = archive.appSamples.last?.date ?? .distantPast
        lastSavedAt = fileModificationDate(archiveURL)
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else {
                return
            }
            saveNow()
        }
    }

    private func saveNow() {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        guard let data = try? JSONEncoder.lifeTracker.encode(archive) else {
            return
        }
        if (try? data.write(to: archiveURL, options: [.atomic])) != nil {
            lastSavedAt = Date()
        }
    }

    private func fileModificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }

    private var latestUserFacingAppName: String? {
        archive.appSamples.last(where: { isUserFacingAppName($0.appName) })?.appName
    }

    private func isUserFacingAppName(_ name: String) -> Bool {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, normalized != "unknown" else {
            return false
        }
        let ignored: Set<String> = [
            "loginwindow",
            "windowserver",
            "systemuiserver",
            "control center",
            "notification center",
            "spotlight",
            "siri",
            "universalcontrol",
            "universal control"
        ]
        return !ignored.contains(normalized)
    }
}

private extension JSONEncoder {
    static var lifeTracker: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var lifeTracker: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
