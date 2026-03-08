import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var claudeProvider: ClaudeProvider!
    private let scheduler = RefreshScheduler()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupProvider()
        setupStatusItem()
        setupPopover()
        startScheduler()
    }

    func applicationWillTerminate(_ notification: Notification) {
        scheduler.stop()
    }

    // MARK: - 초기 설정

    private func setupProvider() {
        claudeProvider = ClaudeProvider()
        ProviderRegistry.shared.register(claudeProvider)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.attributedTitle = makeMenuBarText(h: "--", hColor: .secondaryLabelColor, d: "--", dColor: .secondaryLabelColor)
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: Constants.popoverWidth, height: Constants.popoverHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(scheduler: scheduler))
    }

    // MARK: - 스마트 폴링

    private func startScheduler() {
        scheduler.start { [weak self] in
            await self?.fetchAndUpdateMenuBar()
        }
        // 최초 1회 즉시 요청
        Task { await fetchAndUpdateMenuBar() }
    }

    // MARK: - 팝오버

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            Task { await fetchAndUpdateMenuBar() }
        }
    }

    // MARK: - 데이터 갱신

    private func fetchAndUpdateMenuBar() async {
        do {
            let usage = try await claudeProvider.fetchUsage()
            updateMenuBarText(usage: usage)
            scheduler.reportSuccess()
        } catch let error as ClaudeAPIError where error == .rateLimited {
            print("[TokenGauge] 429 rate limited")
            scheduler.reportRateLimited()
            // 캐시 데이터가 있으면 표시
            if let cached = claudeProvider.currentUsage {
                updateMenuBarText(usage: cached)
            }
        } catch {
            print("[TokenGauge] \(error.localizedDescription)")
            statusItem.button?.attributedTitle = makeMenuBarText(
                h: "--", hColor: .secondaryLabelColor,
                d: "--", dColor: .secondaryLabelColor
            )
        }
    }

    // MARK: - 메뉴바 색상 텍스트

    private func updateMenuBarText(usage: UsageData) {
        let fiveHour = usage.limits.first { $0.id == "five_hour" }
        let sevenDay = usage.limits.first { $0.id == "seven_day" }

        let h = fiveHour.map { "\(Int($0.usedPercentage))%" } ?? "--"
        let hColor = fiveHour?.severityLevel.nsColor ?? .secondaryLabelColor
        let d = sevenDay.map { "\(Int($0.usedPercentage))%" } ?? "--"
        let dColor = sevenDay?.severityLevel.nsColor ?? .secondaryLabelColor

        statusItem.button?.attributedTitle = makeMenuBarText(h: h, hColor: hColor, d: d, dColor: dColor)
    }

    private func makeMenuBarText(h: String, hColor: NSColor, d: String, dColor: NSColor) -> NSAttributedString {
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: font]

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "5h:[", attributes: labelAttrs))
        result.append(NSAttributedString(string: h, attributes: [.font: font, .foregroundColor: hColor]))
        result.append(NSAttributedString(string: "] | 7d:[", attributes: labelAttrs))
        result.append(NSAttributedString(string: d, attributes: [.font: font, .foregroundColor: dColor]))
        result.append(NSAttributedString(string: "]", attributes: labelAttrs))
        return result
    }
}
