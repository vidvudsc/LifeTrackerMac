import Foundation

enum FileContentAnalyzer {
    private static let maxBytes = 512 * 1024
    private static let trackedExtensions: Set<String> = [
        ".swift", ".py", ".js", ".ts", ".tsx", ".jsx", ".html", ".css",
        ".c", ".h", ".cpp", ".hpp", ".m", ".mm", ".rs", ".go", ".java",
        ".md", ".txt", ".json", ".yaml", ".yml", ".toml", ".sh", ".sql"
    ]
    private static let ignoredTokens: Set<String> = [
        "the", "and", "for", "with", "from", "this", "that", "true", "false",
        "null", "none", "let", "var", "func", "class", "struct", "import",
        "return", "if", "else", "while", "for", "in", "to", "of"
    ]

    static func analyze(url: URL, project: String, ext: String, previous: FileContentSnapshot?, date: Date) -> (FileContentSnapshot?, FileChangeSummary?) {
        guard trackedExtensions.contains(ext) else {
            return (nil, nil)
        }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              size.intValue <= maxBytes else {
            return (nil, nil)
        }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            return (nil, nil)
        }

        let lines = text.components(separatedBy: .newlines)
        let snapshot = FileContentSnapshot(
            path: url.path,
            hash: text.hashValue,
            lineCount: lines.count,
            nonEmptyLineCount: lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
            tokenCounts: tokenCounts(in: text),
            symbols: symbols(in: text, ext: ext)
        )

        guard let previous, previous.hash != snapshot.hash else {
            return (snapshot, nil)
        }

        let tokenDelta = changedTokenCount(previous.tokenCounts, snapshot.tokenCounts)
        let addedSymbols = Array(Set(snapshot.symbols).subtracting(previous.symbols)).sorted().prefix(8).map { $0 }
        let removedSymbols = Array(Set(previous.symbols).subtracting(snapshot.symbols)).sorted().prefix(8).map { $0 }
        let lineDelta = snapshot.nonEmptyLineCount - previous.nonEmptyLineCount
        let estimatedAdded = max(0, lineDelta) + tokenDelta / 12
        let estimatedRemoved = max(0, -lineDelta) + tokenDelta / 14

        return (
            snapshot,
            FileChangeSummary(
                id: UUID(),
                date: date,
                path: url.path,
                project: project,
                ext: ext,
                lineDelta: lineDelta,
                estimatedAddedLines: estimatedAdded,
                estimatedRemovedLines: estimatedRemoved,
                changedTokenCount: tokenDelta,
                addedSymbols: addedSymbols,
                removedSymbols: removedSymbols
            )
        )
    }

    private static func tokenCounts(in text: String) -> [String: Int] {
        let pieces = text.lowercased().split { character in
            !(character.isLetter || character.isNumber || character == "_")
        }
        var counts: [String: Int] = [:]
        for piece in pieces {
            let token = String(piece)
            guard token.count >= 3, !ignoredTokens.contains(token), !token.allSatisfy(\.isNumber) else {
                continue
            }
            counts[token, default: 0] += 1
        }
        return counts
    }

    private static func symbols(in text: String, ext: String) -> [String] {
        let patterns: [String]
        switch ext {
        case ".swift":
            patterns = [#"\b(func|class|struct|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)"#]
        case ".py":
            patterns = [#"\b(def|class)\s+([A-Za-z_][A-Za-z0-9_]*)"#]
        case ".js", ".ts", ".tsx", ".jsx":
            patterns = [#"\b(function|class)\s+([A-Za-z_][A-Za-z0-9_]*)"#, #"\b(?:const|let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:async\s*)?\("#]
        case ".c", ".h", ".cpp", ".hpp", ".m", ".mm":
            patterns = [#"\b([A-Za-z_][A-Za-z0-9_]*)\s*\([^;{}]*\)\s*\{"#]
        default:
            patterns = []
        }

        var output: Set<String> = []
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                continue
            }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            for match in regex.matches(in: text, range: range) {
                let captureIndex = match.numberOfRanges > 2 ? 2 : 1
                guard let symbolRange = Range(match.range(at: captureIndex), in: text) else {
                    continue
                }
                output.insert(String(text[symbolRange]))
            }
        }
        return Array(output).sorted()
    }

    private static func changedTokenCount(_ old: [String: Int], _ new: [String: Int]) -> Int {
        var total = 0
        for key in Set(old.keys).union(new.keys) {
            total += abs((new[key] ?? 0) - (old[key] ?? 0))
        }
        return total
    }
}
