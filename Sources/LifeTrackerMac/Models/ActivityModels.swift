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

struct DashboardRangeStats {
    var totalMinutes: Int = 0
    var focusMinutes: Int = 0
    var codingMinutes: Int = 0
    var previousTotalMinutes: Int = 0
    var previousFocusMinutes: Int = 0
    var previousCodingMinutes: Int = 0
    var projectCount: Int = 0
    var fileCount: Int = 0
    var sessionCount: Int = 0
    var averageEnergy: Int = 0

    var focusShare: Int {
        percentage(focusMinutes, of: totalMinutes)
    }

    var codingShare: Int {
        percentage(codingMinutes, of: totalMinutes)
    }

    var totalDelta: Int {
        percentageDelta(current: totalMinutes, previous: previousTotalMinutes)
    }

    var focusDelta: Int {
        percentageDelta(current: focusMinutes, previous: previousFocusMinutes)
    }

    var codingDelta: Int {
        percentageDelta(current: codingMinutes, previous: previousCodingMinutes)
    }

    private func percentage(_ value: Int, of total: Int) -> Int {
        guard total > 0 else {
            return 0
        }
        return Int((Double(value) / Double(total) * 100).rounded())
    }

    private func percentageDelta(current: Int, previous: Int) -> Int {
        guard previous > 0 else {
            return current > 0 ? 100 : 0
        }
        return Int(((Double(current - previous) / Double(previous)) * 100).rounded())
    }
}

struct DailyEnergyPoint: Identifiable {
    var id: Date { date }
    var date: Date
    var label: String
    var monthLabel: String
    var dayLabel: String
    var score: Double
    var minutes: Int
    var events: Int
    var files: Int
    var changes: Int

    var energyValue: Int {
        Int(score.rounded())
    }

    var helpText: String {
        "\(label): \(energyValue) energy, \(LTFormat.minutes(minutes)), \(events) events, \(files) files, \(changes) content changes"
    }
}

struct HourlyEnergyPoint: Identifiable {
    var id: Date { date }
    var date: Date
    var hourLabel: String
    var score: Double
    var minutes: Int
    var events: Int
    var files: Int
    var changes: Int

    var energyValue: Int {
        Int(score.rounded())
    }

    var helpText: String {
        "\(hourLabel): \(energyValue) energy, \(LTFormat.minutes(minutes)), \(events) events, \(files) files, \(changes) content changes"
    }
}

struct DashboardInsight: Identifiable {
    var id = UUID()
    var systemImage: String
    var title: String
    var value: String
    var detail: String
}
