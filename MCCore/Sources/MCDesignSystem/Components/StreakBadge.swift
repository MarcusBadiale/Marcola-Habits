import SwiftUI

public struct StreakBadge: View {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(badgeColor)
                .font(.caption)

            Text("\(count)")
                .font(MCTypography.progressLabel)
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, MCSpacing.sm)
        .padding(.vertical, MCSpacing.xs)
        .background(badgeColor.opacity(0.12), in: Capsule())
    }

    private var badgeColor: Color {
        switch count {
        case ..<1: .secondary
        case 1..<7: MCColors.warning
        case 7..<30: Color.orange
        default: MCColors.danger
        }
    }
}

#Preview {
    HStack(spacing: MCSpacing.md) {
        StreakBadge(count: 0)
        StreakBadge(count: 3)
        StreakBadge(count: 14)
        StreakBadge(count: 45)
    }
    .padding()
}
