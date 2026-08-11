import MCDesignSystem
import SwiftUI

/// Os números do topo: taxa de conclusão do período num `ProgressRing` e o melhor streak.
///
/// A taxa é uma razão agregada (feitos ÷ agendados no período), não a média das taxas por hábito —
/// por isso ela não "fecha" com os percentuais da lista, e isso é intencional.
struct StatsSummaryCard: View {

    let rate: Double
    let bestStreak: Int
    let periodTitle: String
    let identifierPrefix: String
    /// Só a tela de detalhe mostra o streak atual — na agregada não existe "o" streak.
    var currentStreak: Int? = nil

    /// Com a terceira coluna (streak atual, só no detalhe) o anel encolhe pra sobrar largura
    /// pros labels — senão "Completion" quebra em duas linhas no iPhone.
    private var ringSize: CGFloat { currentStreak == nil ? 96 : 76 }

    var body: some View {
        HStack(spacing: MCSpacing.lg) {
            rateRing
            Divider().frame(height: ringSize * 0.6)
            streak

            if let currentStreak {
                Divider().frame(height: ringSize * 0.6)
                current(currentStreak)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground, in: RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius, style: .continuous))
    }

    private var rateRing: some View {
        VStack(spacing: MCSpacing.sm) {
            ProgressRing(progress: rate, lineWidth: 8, color: MCColors.success)
                .frame(width: ringSize, height: ringSize)
                .overlay {
                    Text(rate.formatted(.percent.precision(.fractionLength(0))))
                        .font(MCTypography.title)
                        .monospacedDigit()
                }
            caption("Completion")
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(identifierPrefix)-completion-rate")
    }

    /// Labels não quebram linha — o layout se ajusta ao redor delas, não o contrário.
    private func caption(_ text: String) -> some View {
        Text(text)
            .font(MCTypography.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var streak: some View {
        VStack(spacing: MCSpacing.sm) {
            StreakBadge(count: bestStreak)
            caption("Best streak")
            Text(periodTitle)
                .font(MCTypography.captionSecondary)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(identifierPrefix)-best-streak")
    }

    private func current(_ count: Int) -> some View {
        VStack(spacing: MCSpacing.sm) {
            StreakBadge(count: count)
            caption("Current")
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(identifierPrefix)-current-streak")
    }
}

#Preview {
    VStack(spacing: MCSpacing.lg) {
        StatsSummaryCard(rate: 0.78, bestStreak: 12, periodTitle: "Last 30 days", identifierPrefix: "preview")
        StatsSummaryCard(rate: 0, bestStreak: 0, periodTitle: "Last 7 days", identifierPrefix: "preview-empty")
        StatsSummaryCard(
            rate: 0.62, bestStreak: 14, periodTitle: "Last 90 days",
            identifierPrefix: "preview-detail", currentStreak: 5
        )
    }
    .padding()
}
