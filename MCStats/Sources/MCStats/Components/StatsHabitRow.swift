import MCDesignSystem
import MCDomain
import SwiftUI

/// Linha de hábito da tela agregada: header com nome, streak e taxa, e embaixo a tira de dias.
///
/// Não reusa o `HabitCard` do design system: aquele tem `onToggle` obrigatório e semântica de
/// "completar hoje", que aqui não faz sentido — esta tela é read-only.
struct StatsHabitRow: View {

    let name: String
    let icon: String
    let colorHex: String
    let streak: Int
    let rate: Double
    let days: [DayActivityDTO]
    let identifierPrefix: String

    private var tint: Color { Color(hex: colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            header
            HabitActivityStrip(
                days: days,
                tint: tint,
                identifierPrefix: "\(identifierPrefix)-strip"
            )
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground, in: RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius, style: .continuous))
        .contentShape(Rectangle())
        // `.contain` faz a linha ser UM elemento identificável sem engolir as células da tira. Sem
        // isso o identifier propaga pros filhos e a query de UI test acha vários matches.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifierPrefix)
    }

    private var header: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: icon)
                .font(MCTypography.headline)
                .foregroundStyle(tint)
                .frame(width: MCSpacing.iconSize)

            Text(name)
                .font(MCTypography.headline)
                .lineLimit(1)

            Spacer(minLength: MCSpacing.sm)

            if streak > 0 {
                StreakBadge(count: streak)
            }

            Text(rate.formatted(.percent.precision(.fractionLength(0))))
                .font(MCTypography.progressLabel)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(MCTypography.captionSecondary)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    VStack(spacing: MCSpacing.md) {
        StatsHabitRow(
            name: "Beber água", icon: "drop.fill", colorHex: "#EF4444",
            streak: 11, rate: 0.86,
            days: PreviewActivity.days(count: 30),
            identifierPrefix: "preview-row-0"
        )
        StatsHabitRow(
            name: "Ler", icon: "book.fill", colorHex: "#F59E0B",
            streak: 0, rate: 0.4,
            days: PreviewActivity.days(count: 90),
            identifierPrefix: "preview-row-1"
        )
    }
    .padding()
}
