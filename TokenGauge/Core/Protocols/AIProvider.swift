import Foundation

protocol AIProvider: AnyObject, Identifiable {
    var id: String { get }
    var displayName: String { get }
    var iconName: String { get }
    var isEnabled: Bool { get set }

    var authType: AuthType { get }
    var isAuthenticated: Bool { get }
    var status: ProviderStatus { get }

    func authenticate(credential: String) async throws
    func fetchUsage() async throws -> UsageData
    func validateCredential() async throws -> Bool
    func logout() async throws
}
