import SwiftUI

struct ProgressBarView: View {
    let limit: UsageLimit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(limit.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(limit.usedPercentage))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(limit.severityLevel.color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(limit.severityLevel.color)
                        .frame(width: geometry.size.width * min(limit.usedPercentage / 100.0, 1.0))
                }
            }
            .frame(height: 6)

            if let resetsAt = limit.resetsAt {
                Text(TimeFormatter.resetDateFormat(resetsAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
