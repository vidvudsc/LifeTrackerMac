import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let item: NSStatusItem
    private let store: ActivityStore
    private let popover = NSPopover()
    private var updateTimer: Timer?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    init(store: ActivityStore = .shared) {
        self.store = store
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        configurePopover()
        update()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
    }

    private func configureButton() {
        guard let button = item.button else {
            return
        }
        button.title = "LT"
        button.font = .systemFont(ofSize: 12, weight: .semibold)
        button.image = statusImage()
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(togglePopover)
    }

    private func configurePopover() {
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.contentSize = NSSize(width: 340, height: 500)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(dismissPopover: { [weak self] in
                self?.closePopover()
            })
                .environmentObject(store)
        )
    }

    private func update() {
        guard let button = item.button else {
            return
        }
        let stats = store.stats
        button.title = "LT \(compactMinutes(stats.todayMinutes))"
        button.image = statusImage()
    }

    private func statusImage() -> NSImage? {
        let url = Bundle.module.url(forResource: "searchIcon", withExtension: "png")
            ?? Bundle.main.url(forResource: "searchIcon", withExtension: "png")
        guard let url, let image = NSImage(contentsOf: url) else {
            return NSImage(systemSymbolName: "magnifyingglass.circle.fill", accessibilityDescription: "LifeTracker")
        }
        image.size = NSSize(width: 20, height: 20)
        image.isTemplate = false
        return image
    }

    private func compactMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = Double(minutes) / 60.0
        return String(format: "%.1fh", hours)
    }

    @objc private func togglePopover() {
        guard let button = item.button else {
            return
        }
        if popover.isShown {
            closePopover()
        } else {
            update()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startDismissMonitors()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        stopDismissMonitors()
    }

    private func startDismissMonitors() {
        stopDismissMonitors()

        let events: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            guard let self else {
                return event
            }
            if self.shouldClosePopover(for: event) {
                self.closePopover()
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    private func stopDismissMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

    private func shouldClosePopover(for event: NSEvent) -> Bool {
        guard popover.isShown else {
            return false
        }
        if event.window === popover.contentViewController?.view.window {
            return false
        }
        if event.window === item.button?.window {
            return false
        }
        return true
    }
}
