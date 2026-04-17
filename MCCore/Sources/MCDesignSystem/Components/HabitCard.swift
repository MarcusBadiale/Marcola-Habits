import SwiftUI

public struct HabitCard: View {
    public let name: String
    public let icon: String
    public let colorHex: String
    public let isCompleted: Bool
    public let streak: Int
    public let progress: Double
    public let onToggle: () -> Void

    public init(
        name: String,
        icon: String,
        colorHex: String,
        isCompleted: Bool,
        streak: Int = 0,
        progress: Double = 0,
        onToggle: @escaping () -> Void
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isCompleted = isCompleted
        self.streak = streak
        self.progress = progress
        self.onToggle = onToggle
    }

    private var habitColor: Color { Color(hex: colorHex) }

    public var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(habitColor)
                .frame(width: MCSpacing.iconSize, height: MCSpacing.iconSize)

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(name)
                    .font(MCTypography.headline)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)

                if streak > 0 {
                    StreakBadge(count: streak)
                }
            }

            Spacer()

            if progress > 0 && progress < 1 {
                ProgressRing(progress: progress, lineWidth: 3, color: habitColor)
                    .frame(width: 32, height: 32)
            }

            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? habitColor : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground, in: RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius))
    }
}

#Preview {
    VStack(spacing: MCSpacing.md) {
        HabitCard(
            name: "Beber água",
            icon: "drop.fill",
            colorHex: "#3B82F6",
            isCompleted: false,
            streak: 5,
            progress: 0.6,
            onToggle: {}
        )

        HabitCard(
            name: "Meditar",
            icon: "brain.head.profile",
            colorHex: "#22C55E",
            isCompleted: true,
            streak: 12,
            onToggle: {}
        )

        HabitCard(
            name: "Exercício",
            icon: "figure.run",
            colorHex: "#EF4444",
            isCompleted: false,
            onToggle: {}
        )
    }
    .padding()
}
