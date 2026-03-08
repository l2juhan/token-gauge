import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var claudeProvider: ClaudeProvider!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupProvider()
        setupStatusItem()
        setupPopover()

        Task {
            await fetchAndUpdateMenuBar()
        }
    }

    private func setupProvider() {
        claudeProvider = ClaudeProvider()
        ProviderRegistry.shared.register(claudeProvider)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "TG: --"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: Constants.popoverWidth, height: Constants.popoverHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView())
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // 팝오버 열 때마다 최신 데이터 요청
            Task { await fetchAndUpdateMenuBar() }
        }
    }

    private func fetchAndUpdateMenuBar() async {
        do {
            let usage = try await claudeProvider.fetchUsage()
            updateMenuBarText(usage: usage)
        } catch {
            print("[TokenGauge] \(error.localizedDescription)")
            statusItem.button?.title = "TG: --"
        }
    }

    private func updateMenuBarText(usage: UsageData) {
        let fiveHour = usage.limits.first { $0.id == "five_hour" }
        let sevenDay = usage.limits.first { $0.id == "seven_day" }

        let h = fiveHour.map { "\(Int($0.usedPercentage))%" } ?? "--"
        let d = sevenDay.map { "\(Int($0.usedPercentage))%" } ?? "--"

        statusItem.button?.title = "5h:\(h) 7d:\(d)"
    }
}
