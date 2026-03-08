import Foundation

struct UsageData: Codable, Identifiable, Sendable {
    let id: UUID
    let provider: String
    let limits: [UsageLimit]
    let extraUsage: UsageLimit?
    let plan: String?
    let fetchedAt: Date

    init(provider: String, limits: [UsageLimit], extraUsage: UsageLimit? = nil, plan: String? = nil) {
        self.id = UUID()
        self.provider = provider
        self.limits = limits
        self.extraUsage = extraUsage
        self.plan = plan
        self.fetchedAt = Date()
    }
}
