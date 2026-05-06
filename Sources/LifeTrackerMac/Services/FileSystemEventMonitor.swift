import CoreServices
import Foundation

struct FileSystemChange {
    var path: String
    var flags: FSEventStreamEventFlags
}

final class FileSystemEventMonitor: @unchecked Sendable {
    private let roots: [URL]
    private let onChanges: @Sendable ([FileSystemChange]) -> Void
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "LifeTrackerMac.FSEvents", qos: .utility)

    init(roots: [URL], onChanges: @escaping @Sendable ([FileSystemChange]) -> Void) {
        self.roots = roots
        self.onChanges = onChanges
    }

    func start() {
        guard stream == nil else {
            return
        }

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, count, eventPaths, eventFlags, _ in
            guard let info else {
                return
            }
            let monitor = Unmanaged<FileSystemEventMonitor>.fromOpaque(info).takeUnretainedValue()
            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
            var changes: [FileSystemChange] = []
            for index in 0..<count {
                guard index < paths.count else {
                    continue
                }
                changes.append(FileSystemChange(path: paths[index], flags: eventFlags[index]))
            }
            monitor.emit(changes)
        }

        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            roots.map(\.path) as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            2.0,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream else {
            return
        }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else {
            return
        }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    private func emit(_ changes: [FileSystemChange]) {
        guard !changes.isEmpty else {
            return
        }
        DispatchQueue.main.async {
            self.onChanges(changes)
        }
    }
}
