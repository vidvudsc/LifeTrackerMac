import Foundation

enum IgnoreRules {
    static let ignoredDirectories: Set<String> = [
        ".git", ".hg", ".svn", ".cache", ".mypy_cache", ".pytest_cache",
        ".ruff_cache", ".venv", "venv", "env", "__pycache__", "node_modules",
        "dist", "build", "DerivedData", ".next", ".nuxt", "target", ".tox",
        ".idea", ".vscode"
    ]

    static let sensitiveNames: Set<String> = [
        ".env", ".env.local", ".env.production", ".npmrc", ".pypirc",
        "id_rsa", "id_ed25519", "known_hosts"
    ]

    static let ignoredExtensions: Set<String> = [
        "pem", "key", "p12", "pfx", "crt", "sqlite", "sqlite3", "db",
        "pyc", "o", "a", "so", "dylib", "dll", "exe", "bin", "pt", "pth",
        "onnx", "mp4", "mov", "mkv", "avi", "ts", "jpg", "jpeg", "png",
        "gif", "webp", "heic", "fit", "fits", "parquet"
    ]

    static func shouldIgnore(_ url: URL, root: URL) -> Bool {
        let components = url.path.replacingOccurrences(of: root.path, with: "").split(separator: "/").map(String.init)
        for component in components {
            if ignoredDirectories.contains(component) || component.hasSuffix(".app") {
                return true
            }
            if component.hasPrefix(".") {
                return true
            }
        }

        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        if sensitiveNames.contains(name) || ignoredExtensions.contains(ext) {
            return true
        }
        if name.hasSuffix(".secret") || name.hasSuffix(".token") {
            return true
        }
        return false
    }

    static func projectName(for url: URL, root: URL) -> String {
        let relative = url.path.replacingOccurrences(of: root.path, with: "")
            .split(separator: "/")
            .map(String.init)
        return relative.first ?? root.lastPathComponent
    }
}
