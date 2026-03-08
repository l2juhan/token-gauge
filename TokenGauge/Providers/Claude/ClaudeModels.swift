import Foundation

// MARK: - API 응답 모델

struct ClaudeUsageResponse: Codable, Sendable {
    let fiveHour: ClaudeUsageWindow?
    let sevenDay: ClaudeUsageWindow?
    let sevenDaySonnet: ClaudeUsageWindow?
    let sevenDayOpus: ClaudeUsageWindow?
    let extraUsage: ClaudeExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case extraUsage = "extra_usage"
    }
}

struct ClaudeUsageWindow: Codable, Sendable {
    let utilization: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct ClaudeExtraUsage: Codable, Sendable {
    let isEnabled: Bool?
    let utilization: Double?
    let usedCredits: Double?    // 센트 단위
    let monthlyLimit: Double?   // 센트 단위

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case utilization
        case usedCredits = "used_credits"
        case monthlyLimit = "monthly_limit"
    }
}

// MARK: - Keychain 자격증명 모델

struct ClaudeCredentials: Codable {
    let claudeAiOauth: ClaudeOAuthToken?
}

struct ClaudeOAuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Double?  // Unix timestamp (밀리초)
}
