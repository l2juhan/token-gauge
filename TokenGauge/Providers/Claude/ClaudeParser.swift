import Foundation

enum ClaudeParser {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func parse(_ response: ClaudeUsageResponse) -> UsageData {
        var limits: [UsageLimit] = []

        if let fiveHour = response.fiveHour {
            limits.append(makeLimit(
                id: "five_hour", label: "플랜 사용량 한도",
                window: fiveHour
            ))
        }

        if let sevenDay = response.sevenDay {
            limits.append(makeLimit(
                id: "seven_day", label: "주간 한도",
                window: sevenDay
            ))
        }

        if let sonnet = response.sevenDaySonnet {
            limits.append(makeLimit(
                id: "seven_day_sonnet", label: "Sonnet만",
                window: sonnet
            ))
        }

        // extra_usage는 별도 구조
        let extraUsage: UsageLimit? = {
            guard let extra = response.extraUsage else { return nil }
            return UsageLimit(
                id: "extra_usage",
                label: "추가 사용량",
                usedPercentage: extra.utilization ?? 0,
                resetsAt: nil
            )
        }()

        return UsageData(
            provider: "claude",
            limits: limits,
            extraUsage: extraUsage
        )
    }

    private static func makeLimit(id: String, label: String, window: ClaudeUsageWindow) -> UsageLimit {
        UsageLimit(
            id: id,
            label: label,
            usedPercentage: window.utilization,
            resetsAt: window.resetsAt.flatMap { isoFormatter.date(from: $0) }
        )
    }
}
