import Foundation

enum UsageCacheService {
    // TokenGauge 자체 캐시
    private static let cacheURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/tokengauge_cache.json")
    }()

    // cc-alchemy-statusline 캐시 (읽기 전용 fallback)
    private static let alchemyCacheURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/statusline_cache.json")
    }()

    // MARK: - 저장 (API 성공 시 호출)

    static func save(_ response: ClaudeUsageResponse) {
        let cache = CachedResponse(
            cachedAt: ISO8601DateFormatter().string(from: Date()),
            fiveHour: response.fiveHour,
            sevenDay: response.sevenDay,
            sevenDaySonnet: response.sevenDaySonnet,
            sevenDayOpus: response.sevenDayOpus,
            extraUsage: response.extraUsage
        )
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    // MARK: - 읽기 (429 fallback)

    static func loadCached() -> UsageData? {
        // 1) TokenGauge 자체 캐시 우선
        if let data = try? Data(contentsOf: cacheURL),
           let cache = try? JSONDecoder().decode(CachedResponse.self, from: data) {
            return parseOwnCache(cache)
        }

        // 2) cc-alchemy 캐시 fallback
        if let data = try? Data(contentsOf: alchemyCacheURL),
           let cache = try? JSONDecoder().decode(AlchemyCache.self, from: data) {
            return parseAlchemyCache(cache)
        }

        return nil
    }

    // MARK: - TokenGauge 캐시 파싱

    private static func parseOwnCache(_ cache: CachedResponse) -> UsageData {
        let response = ClaudeUsageResponse(
            fiveHour: cache.fiveHour,
            sevenDay: cache.sevenDay,
            sevenDaySonnet: cache.sevenDaySonnet,
            sevenDayOpus: cache.sevenDayOpus,
            extraUsage: cache.extraUsage
        )
        return ClaudeParser.parse(response)
    }

    // MARK: - cc-alchemy 캐시 파싱

    private static func parseAlchemyCache(_ cache: AlchemyCache) -> UsageData {
        let response = ClaudeUsageResponse(
            fiveHour: cache.fiveHour,
            sevenDay: cache.sevenDay,
            sevenDaySonnet: nil,
            sevenDayOpus: nil,
            extraUsage: nil
        )
        return ClaudeParser.parse(response)
    }
}

// MARK: - TokenGauge 캐시 모델

private struct CachedResponse: Codable {
    let cachedAt: String
    let fiveHour: ClaudeUsageWindow?
    let sevenDay: ClaudeUsageWindow?
    let sevenDaySonnet: ClaudeUsageWindow?
    let sevenDayOpus: ClaudeUsageWindow?
    let extraUsage: ClaudeExtraUsage?

    enum CodingKeys: String, CodingKey {
        case cachedAt = "cached_at"
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case extraUsage = "extra_usage"
    }
}

// MARK: - cc-alchemy 캐시 모델 (읽기 전용)

private struct AlchemyCache: Codable {
    let cachedAt: String?
    let fiveHour: ClaudeUsageWindow?
    let sevenDay: ClaudeUsageWindow?

    enum CodingKeys: String, CodingKey {
        case cachedAt = "cached_at"
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}
