import SwiftUI

struct PopoverView: View {
    private var registry = ProviderRegistry.shared

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("TokenGauge")
                    .font(.headline)
                Spacer()
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)

            Divider()

            if let claude = registry.providers.first(where: { $0.id == "claude" }) as? ClaudeProvider,
               let usage = claude.currentUsage {
                UsageCardView(
                    providerName: claude.displayName,
                    limits: usage.limits,
                    extraUsage: usage.extraUsage
                )
            } else {
                // 데이터 로딩 중 또는 인증 안 됨
                VStack(spacing: 8) {
                    ProgressView()
                    Text("데이터 불러오는 중...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .frame(width: Constants.popoverWidth, height: Constants.popoverHeight)
    }

    private func refresh() {
        Task {
            await ProviderRegistry.shared.refreshAll()
        }
    }
}
