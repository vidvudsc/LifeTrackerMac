import AppKit
import Foundation

enum ForegroundAppTracker {
    static func currentAppName() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }
}
