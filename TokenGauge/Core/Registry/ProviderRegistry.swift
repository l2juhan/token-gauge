import Observation

@Observable
class ProviderRegistry {
    static let shared = ProviderRegistry()

    private(set) var providers: [any AIProvider] = []

    private init() {}

    func register(_ provider: any AIProvider) {
        providers.append(provider)
    }

    var enabledProviders: [any AIProvider] {
        providers.filter { $0.isEnabled }
    }

    func refreshAll() async {
        for provider in enabledProviders {
            do {
                _ = try await provider.fetchUsage()
            } catch {
                print("[\(provider.id)] refresh failed: \(error)")
            }
        }
    }
}
