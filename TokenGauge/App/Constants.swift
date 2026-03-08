import Foundation

enum Constants {
    // MARK: - UI
    static let popoverWidth: CGFloat = 320
    static let popoverHeight: CGFloat = 400

    // MARK: - Claude API
    static let claudeKeychainService = "Claude Code-credentials"
    static let apiBaseURL = "https://api.anthropic.com"
    static let usageEndpoint = "/api/oauth/usage"
    static let betaHeader = "oauth-2025-04-20"
    static let apiVersion = "2023-06-01"
    static let userAgent = "TokenGauge/1.0"

    // MARK: - 폴링
    static let activePollingInterval: TimeInterval = 300   // 5분
    static let idlePollingInterval: TimeInterval = 3600    // 1시간
    static let maxBackoffInterval: TimeInterval = 1800     // 30분

    // MARK: - 감시 대상 Bundle IDs
    enum BundleIDs {
        static let claudeDesktop = "com.anthropic.claudeDesktop"
        static let chatGPT = "com.openai.chat"       // Phase 3
    }
}
