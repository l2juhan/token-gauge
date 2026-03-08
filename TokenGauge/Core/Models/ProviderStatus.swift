import Foundation

enum ProviderStatus: Sendable {
    case active
    case stale
    case authExpired
    case error(String)
    case disconnected
}
