import Foundation

struct FileSnapshot: Codable, Equatable {
    var path: String
    var root: String
    var project: String
    var ext: String
    var size: Int64
    var modifiedAt: Date
}

struct FileActivityEvent: Codable, Identifiable {
    var id: UUID
    var date: Date
    var type: EventType
    var path: String
    var project: String
    var ext: String
    var size: Int64

    enum EventType: String, Codable {
        case created
        case modified
        case deleted
    }
}

struct FileContentSnapshot: Codable {
    var path: String
    var hash: Int
    var lineCount: Int
    var nonEmptyLineCount: Int
    var tokenCounts: [String: Int]
    var symbols: [String]
}

struct FileChangeSummary: Codable, Identifiable {
    var id: UUID
    var date: Date
    var path: String
    var project: String
    var ext: String
    var lineDelta: Int
    var estimatedAddedLines: Int
    var estimatedRemovedLines: Int
    var changedTokenCount: Int
    var addedSymbols: [String]
    var removedSymbols: [String]
}

struct AppFocusSample: Codable, Identifiable {
    var id: UUID
    var date: Date
    var appName: String
}

struct WorkSession: Identifiable {
    var id = UUID()
    var project: String
    var start: Date
    var end: Date
    var eventCount: Int
    var fileCount: Int
    var extensions: [String]

    var minutes: Int {
        max(1, Int(end.timeIntervalSince(start) / 60.0.rounded()))
    }
}

struct ActivityArchive: Codable {
    var events: [FileActivityEvent] = []
    var appSamples: [AppFocusSample] = []
    var contentSnapshots: [String: FileContentSnapshot] = [:]
    var contentChanges: [FileChangeSummary] = []
}

struct DashboardStats {
    var todayMinutes: Int = 0
    var weekMinutes: Int = 0
    var sessionCount: Int = 0
    var eventCount: Int = 0
    var activeProjectsToday: Int = 0
    var currentApp: String = "-"
    var latestActivity: Date?
    var savedAt: Date?
}
