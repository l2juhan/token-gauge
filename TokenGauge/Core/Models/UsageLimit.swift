import SwiftUI

struct UsageLimit: Codable, Identifiable, Sendable {
    let id: String
    let label: String
    let usedPercentage: Double
    let resetsAt: Date?

    var remainingTime: TimeInterval? {
        guard let resetsAt else { return nil }
        return resetsAt.timeIntervalSinceNow
    }

    var severityLevel: SeverityLevel {
        switch usedPercentage {
        case ..<30:  return .normal
        case ..<60:  return .moderate
        case ..<80:  return .warning
        default:     return .critical
        }
    }
}

enum SeverityLevel: Sendable {
    case normal, moderate, warning, critical

    var color: Color {
        switch self {
        case .normal:   return .green
        case .moderate: return .yellow
        case .warning:  return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Claude 샘플 데이터

extension UsageLimit {
    static let claudeSampleData: [UsageLimit] = [
        UsageLimit(
            id: "five_hour",
            label: "플랜 사용량 한도",
            usedPercentage: 29.0,
            resetsAt: Calendar.current.date(
                bySettingHour: 23, minute: 0, second: 0, of: Date()
            )
        ),
        UsageLimit(
            id: "seven_day",
            label: "주간 한도",
            usedPercentage: 10.0,
            resetsAt: {
                var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
                components.weekday = 6 // 금요일
                components.hour = 15
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date().addingTimeInterval(3600 * 24 * 3)
            }()
        ),
        UsageLimit(
            id: "seven_day_sonnet",
            label: "Sonnet만",
            usedPercentage: 5.0,
            resetsAt: nil
        ),
    ]

    static let extraUsageSample = UsageLimit(
        id: "extra_usage",
        label: "추가 사용량",
        usedPercentage: 0.0,
        resetsAt: nil
    )
}
