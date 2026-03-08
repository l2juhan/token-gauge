import SwiftUI

struct PopoverView: View {
    var registry = ProviderRegistry.shared
    var scheduler: RefreshScheduler

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 헤더
            headerView
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // MARK: - 콘텐츠
            if let claude = registry.providers.first(where: { $0.id == "claude" }) as? ClaudeProvider,
               let usage = claude.currentUsage {
                ScrollView {
                    UsageCardView(
                        providerName: claude.displayName,
                        status: claude.status,
                        limits: usage.limits,
                        extraUsage: usage.extraUsage,
                        fetchedAt: usage.fetchedAt
                    )
                    .padding(.vertical, 8)
                }
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("데이터 불러오는 중...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // MARK: - 푸터
            footerView
                .padding(.horizontal)
                .padding(.vertical, 6)
        }
        .frame(width: Constants.popoverWidth, height: Constants.popoverHeight)
    }

    // MARK: - 헤더

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("TokenGauge")
                    .font(.headline)
                Spacer()
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)

                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
            }

            // 상태 라인
            HStack(spacing: 6) {
                if let claude = registry.providers.first(where: { $0.id == "claude" }) as? ClaudeProvider,
                   let usage = claude.currentUsage {
                    Text(TimeFormatter.relativeFormat(usage.fetchedAt) + " 갱신")

                    if case .stale = claude.status {
                        Text("캐시")
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Circle()
                    .fill(scheduler.isActive ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                Text(scheduler.isActive ? "활성" : "절전")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - 푸터

    private var footerView: some View {
        HStack {
            Text("갱신 주기: \(TimeFormatter.intervalFormat(scheduler.currentInterval))")
            Spacer()
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    private func refresh() {
        Task {
            await ProviderRegistry.shared.refreshAll()
        }
    }
}
