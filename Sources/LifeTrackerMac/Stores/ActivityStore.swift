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
            currentApp: archive.appSamples.last?.appName ?? "-",
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
        Calendar.current.date(byAdding: .day, value: -selectedRangeDays, to: Date()) ?? Date.distantPast
    }

    var recentEvents: [FileActivityEvent] {
        archive.events.filter { $0.date >= rangeStart }.sorted { $0.date > $1.date }
    }

    var recentContentChanges: [FileChangeSummary] {
        archive.contentChanges.filter { $0.date >= rangeStart }.sorted { $0.date > $1.date }
    }

    var recentAppSamples: [AppFocusSample] {
        archive.appSamples.filter { $0.date >= rangeStart }.sorted { $0.date > $1.date }
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
        topApps(since: rangeStart)
    }

    var todayAppFocusMinutes: Int {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return topApps(since: todayStart).reduce(0) { $0 + $1.minutes }
    }

    var todayTopApp: (app: String, minutes: Int)? {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return topApps(since: todayStart).first
    }

    func topApps(since startDate: Date) -> [(app: String, minutes: Int)] {
        var totals: [String: TimeInterval] = [:]
        let samples = archive.appSamples.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
        for index in samples.indices {
            let current = samples[index]
            let nextDate = index + 1 < samples.count ? samples[index + 1].date : Date()
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
        let rows = archive.events.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
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
