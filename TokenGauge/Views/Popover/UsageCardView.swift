import SwiftUI

struct UsageCardView: View {
    let providerName: String
    let status: ProviderStatus
    let limits: [UsageLimit]
    let extraUsage: UsageLimit?
    let fetchedAt: Date

    private var mainLimits: [UsageLimit] {
        limits.filter { $0.isMainLimit }
    }

    private var modelLimits: [UsageLimit] {
        limits.filter { !$0.isMainLimit }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 프로바이더 헤더
            HStack(spacing: 8) {
                ClaudeIconView(size: 24)
                Text(providerName)
                    .font(.subheadline.bold())
                statusDot
                Spacer()
            }

            // 메인 사용량 (5시간, 7일)
            ForEach(mainLimits) { limit in
                ProgressBarView(limit: limit)
            }

            // 모델별 한도
            if !modelLimits.isEmpty {
                sectionHeader("모델별")

                ForEach(modelLimits) { limit in
                    ProgressBarView(limit: limit)
                }
            }

            // 추가 사용량
            if let extra = extraUsage {
                sectionHeader("추가 사용량")
                extraUsageRow(extra)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }

    // MARK: - 상태 표시 dot

    @ViewBuilder
    private var statusDot: some View {
        switch status {
        case .active:
            Circle().fill(.green).frame(width: 7, height: 7)
        case .stale:
            Circle().fill(.orange).frame(width: 7, height: 7)
        case .authExpired:
            Circle().fill(.red).frame(width: 7, height: 7)
        case .error:
            Circle().fill(.red).frame(width: 7, height: 7)
        case .disconnected:
            Circle().fill(.gray).frame(width: 7, height: 7)
        }
    }

    // MARK: - 섹션 헤더

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
        }
        .padding(.top, 2)
    }

    // MARK: - 추가 사용량 행

    private func extraUsageRow(_ extra: UsageLimit) -> some View {
        HStack {
            if let credits = extra.usedCredits, let limit = extra.monthlyLimit, limit > 0 {
                Text(String(format: "$%.2f / $%.2f", credits / 100, limit / 100))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(credits > 0 ? .orange : .secondary)
            }
            Spacer()
            if extra.usedPercentage > 0 {
                Text("\(Int(extra.usedPercentage))% 사용")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.orange)
            } else {
                Text("사용 가능")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}
