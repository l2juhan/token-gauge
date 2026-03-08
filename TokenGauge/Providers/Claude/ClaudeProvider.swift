import Foundation
import Observation

@Observable
class ClaudeProvider: AIProvider {
    let id = "claude"
    let displayName = "Claude"
    let iconName = "ClaudeLogo"
    let authType: AuthType = .oauthKeychain

    var isEnabled = true
    var isAuthenticated = false
    var status: ProviderStatus = .disconnected
    var currentUsage: UsageData?

    func authenticate(credential: String) async throws {
        isAuthenticated = true
        status = .active
    }

    func fetchUsage() async throws -> UsageData {
        let token = try ClaudeAuthService.getAccessToken()
        isAuthenticated = true

        do {
            let response = try await ClaudeAPI.fetchUsage(token: token)
            let usage = ClaudeParser.parse(response)
            currentUsage = usage
            status = .active
            // 성공 시 파일 캐시 저장
            UsageCacheService.save(response)
            return usage
        } catch let error as ClaudeAPIError where error == .rateLimited {
            // 429: stale 상태로 전환
            status = .stale
            // 1) 메모리 캐시
            if let cached = currentUsage { return cached }
            // 2) 파일 캐시 fallback (자체 캐시 → cc-alchemy 캐시)
            if let fileCached = UsageCacheService.loadCached() {
                currentUsage = fileCached
                return fileCached
            }
            throw error
        }
    }

    func validateCredential() async throws -> Bool {
        do {
            _ = try ClaudeAuthService.getAccessToken()
            return true
        } catch {
            return false
        }
    }

    func logout() async throws {
        isAuthenticated = false
        status = .disconnected
        currentUsage = nil
    }
}

