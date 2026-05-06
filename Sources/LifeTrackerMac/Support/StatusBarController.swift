import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let item: NSStatusItem
    private let store: ActivityStore
    private var updateTimer: Timer?
    private var todayItem: NSMenuItem?
    private var currentItem: NSMenuItem?
    private var topAppItem: NSMenuItem?
    private var sessionsItem: NSMenuItem?
    private var eventsItem: NSMenuItem?
    private var latestItem: NSMenuItem?
    private var trackingItem: NSMenuItem?

    init(store: ActivityStore = .shared) {
        self.store = store
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        configureMenu()
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
    }

    private func configureMenu() {
        let menu = NSMenu()
        todayItem = NSMenuItem(title: "Today coding: -", action: nil, keyEquivalent: "")
        currentItem = NSMenuItem(title: "Current app: -", action: nil, keyEquivalent: "")
        topAppItem = NSMenuItem(title: "Top app: -", action: nil, keyEquivalent: "")
        sessionsItem = NSMenuItem(title: "Sessions: -", action: nil, keyEquivalent: "")
        eventsItem = NSMenuItem(title: "File events: -", action: nil, keyEquivalent: "")
        latestItem = NSMenuItem(title: "Latest: -", action: nil, keyEquivalent: "")
        [todayItem, currentItem, topAppItem, sessionsItem, eventsItem, latestItem].compactMap { $0 }.forEach(menu.addItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Show Dashboard", action: #selector(showDashboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide Dashboard", action: #selector(hideDashboard), keyEquivalent: ""))
        trackingItem = NSMenuItem(title: "Stop Tracking", action: #selector(toggleTracking), keyEquivalent: "")
        if let trackingItem {
            menu.addItem(trackingItem)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit LifeTracker", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items {
            item.target = self
        }
        self.item.menu = menu
    }

    private func update() {
        guard let button = item.button else {
            return
        }
        let stats = store.stats
        let todayFocus = store.todayAppFocusMinutes
        button.title = "LT \(compactMinutes(stats.todayMinutes))"
        button.image = statusImage()

        todayItem?.title = "Today coding: \(LTFormat.minutes(stats.todayMinutes)) · Focus: \(LTFormat.minutes(todayFocus))"
        currentItem?.title = "Current app: \(stats.currentApp)"
        if let topApp = store.todayTopApp {
            topAppItem?.title = "Top app: \(topApp.app) · \(LTFormat.minutes(topApp.minutes))"
        } else {
            topAppItem?.title = "Top app: -"
        }
        sessionsItem?.title = "Sessions: \(stats.sessionCount)"
        eventsItem?.title = "File events: \(stats.eventCount)"
        if let latest = stats.latestActivity {
            latestItem?.title = "Latest: \(LTFormat.relative(latest))"
        } else {
            latestItem?.title = "Latest: -"
        }
        trackingItem?.title = store.isTracking ? "Stop Tracking" : "Start Tracking"
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

    @objc private func showDashboard() {
        WindowVisibility.showDashboard()
    }

    @objc private func hideDashboard() {
        WindowVisibility.hideDashboard()
    }

    @objc private func toggleTracking() {
        store.toggleTracking()
        update()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
