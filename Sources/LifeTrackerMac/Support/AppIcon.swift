import AppKit
import Foundation

@MainActor
enum AppIcon {
    static func install() {
        let url = Bundle.module.url(forResource: "iconLife", withExtension: "png")
            ?? Bundle.main.url(forResource: "iconLife", withExtension: "png")
        guard let url, let image = NSImage(contentsOf: url) else {
            return
        }
        NSApp.applicationIconImage = image
    }
}
