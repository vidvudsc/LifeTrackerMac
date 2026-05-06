import Foundation

struct ScanResult {
    var snapshots: [String: FileSnapshot]
    var events: [FileActivityEvent]
    var baselineRootPaths: Set<String>
}

enum FileActivityScanner {
    static func scan(
        roots: [URL],
        previousSnapshots: [String: FileSnapshot],
        baselineRootPaths: Set<String>
    ) -> ScanResult {
        let fileManager = FileManager.default
        var snapshots: [String: FileSnapshot] = [:]
        var events: [FileActivityEvent] = []
        var newBaselineRoots = baselineRootPaths
        let now = Date()

        for root in roots where root.hasDirectoryPath {
            let rootPath = root.path
            let isBaseline = !baselineRootPaths.contains(rootPath)
            if isBaseline {
                newBaselineRoots.insert(rootPath)
            }

            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                if IgnoreRules.shouldIgnore(url, root: root) {
                    if url.hasDirectoryPath {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                      values.isRegularFile == true else {
                    continue
                }

                let snapshot = FileSnapshot(
                    path: url.path,
                    root: rootPath,
                    project: IgnoreRules.projectName(for: url, root: root),
                    ext: url.pathExtension.isEmpty ? "[none]" : ".\(url.pathExtension.lowercased())",
                    size: Int64(values.fileSize ?? 0),
                    modifiedAt: values.contentModificationDate ?? now
                )
                snapshots[url.path] = snapshot

                guard !isBaseline else {
                    continue
                }

                if let previous = previousSnapshots[url.path] {
                    if previous.size != snapshot.size || abs(previous.modifiedAt.timeIntervalSince(snapshot.modifiedAt)) > 0.001 {
                        events.append(
                            FileActivityEvent(
                                id: UUID(),
                                date: now,
                                type: .modified,
                                path: snapshot.path,
                                project: snapshot.project,
                                ext: snapshot.ext,
                                size: snapshot.size
                            )
                        )
                    }
                } else {
                    events.append(
                        FileActivityEvent(
                            id: UUID(),
                            date: now,
                            type: .created,
                            path: snapshot.path,
                            project: snapshot.project,
                            ext: snapshot.ext,
                            size: snapshot.size
                        )
                    )
                }
            }
        }

        for (path, previous) in previousSnapshots where snapshots[path] == nil {
            guard baselineRootPaths.contains(previous.root) else {
                continue
            }
            events.append(
                FileActivityEvent(
                    id: UUID(),
                    date: now,
                    type: .deleted,
                    path: previous.path,
                    project: previous.project,
                    ext: previous.ext,
                    size: previous.size
                )
            )
        }

        return ScanResult(snapshots: snapshots, events: events, baselineRootPaths: newBaselineRoots)
    }
}
