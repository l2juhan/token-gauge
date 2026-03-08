import SwiftUI

struct UsageCardView: View {
    let providerName: String
    let limits: [UsageLimit]
    let extraUsage: UsageLimit?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 프로바이더 헤더
            HStack(spacing: 8) {
                ClaudeIconView(size: 24)
                Text(providerName)
                    .font(.subheadline.bold())
                Spacer()
            }

            // 사용량 바
            ForEach(limits) { limit in
                ProgressBarView(limit: limit)
            }

            // 추가 사용량
            if let extra = extraUsage {
                Divider()

                HStack {
                    Text(extra.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}
