import AppKit
import Observation

@Observable
class RefreshScheduler {
    private(set) var isActive = false
    private(set) var currentInterval: TimeInterval = Constants.idlePollingInterval

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var backoffMultiplier: Int = 0
    @ObservationIgnored private var onRefresh: (@Sendable () async -> Void)?

    // MARK: - 시작 / 정지

    func start(onRefresh: @escaping @Sendable () async -> Void) {
        self.onRefresh = onRefresh
        startObservingApps()
        updateMode()
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        stopObservingApps()
    }

    // MARK: - 429 Backoff

    func reportRateLimited() {
        backoffMultiplier = min(backoffMultiplier + 1, 5)
        let backoff = min(
            Constants.activePollingInterval * pow(2.0, Double(backoffMultiplier)),
            Constants.maxBackoffInterval
        )
        currentInterval = backoff
        scheduleTimer()
        print("[TokenGauge] 429 backoff: \(Int(backoff))초 후 재시도 (x\(backoffMultiplier))")
    }

    func reportSuccess() {
        if backoffMultiplier > 0 {
            backoffMultiplier = 0
            updateMode()
            scheduleTimer()
        }
    }

    // MARK: - 앱 감시 (NSWorkspace)

    private func startObservingApps() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self, selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(appDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification, object: nil
        )
    }

    private func stopObservingApps() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              isMonitoredApp(app.bundleIdentifier) else { return }

        print("[TokenGauge] 감지: \(app.localizedName ?? "AI 앱") 실행됨 → 활성 모드")
        isActive = true
        backoffMultiplier = 0
        currentInterval = Constants.activePollingInterval
        scheduleTimer()

        // 즉시 새로고침
        Task { await onRefresh?() }
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              isMonitoredApp(app.bundleIdentifier) else { return }

        print("[TokenGauge] 감지: \(app.localizedName ?? "AI 앱") 종료됨 → 절전 모드 확인")
        updateMode()
        scheduleTimer()
    }

    // MARK: - 내부

    private func updateMode() {
        let running = isAnyMonitoredRunning()
        isActive = running
        if backoffMultiplier == 0 {
            currentInterval = running ? Constants.activePollingInterval : Constants.idlePollingInterval
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: true) { [weak self] _ in
            Task { await self?.onRefresh?() }
        }
    }

    /// GUI 앱 (NSWorkspace) + CLI 프로세스 모두 확인
    private func isAnyMonitoredRunning() -> Bool {
        // 1) GUI 앱 확인
        let bundleIDs = [Constants.BundleIDs.claudeDesktop]
        let guiRunning = NSWorkspace.shared.runningApplications.contains { app in
            bundleIDs.contains(where: { $0 == app.bundleIdentifier })
        }
        if guiRunning { return true }

        // 2) CLI 프로세스 확인 (Claude Code 등)
        return isAnyCLIProcessRunning()
    }

    private func isAnyCLIProcessRunning() -> Bool {
        for name in Constants.monitoredProcessNames {
            let pipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            process.arguments = ["-x", name]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 { return true }
            } catch {
                continue
            }
        }
        return false
    }

    private func isMonitoredApp(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return [Constants.BundleIDs.claudeDesktop].contains(bundleID)
    }

    deinit {
        stop()
    }
}
