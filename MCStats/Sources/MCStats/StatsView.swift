import MCDesignSystem
import MCDomain
import MCShared
import SwiftUI

struct StatsView: View {

    @Provider var provider = StatsProvider()

    var body: some View {
        Group {
            if provider.isEmpty {
                ContentUnavailableView(
                    "No stats yet",
                    systemImage: "chart.bar.fill",
                    description: Text("Create a habit and check in for a few days.")
                )
                .accessibilityIdentifier("stats-empty-state")
            } else {
                content
            }
        }
        .navigationTitle("Stats")
    }

    private var content: some View {
        // `summary` é lido uma vez por avaliação do body — cada acesso refaz os DTOs e as chamadas
        // ao calculator.
        let summary = provider.summary

        return ScrollView {
            VStack(spacing: MCSpacing.lg) {
                StatsPeriodPicker(period: provider.$period, identifierPrefix: "stats-period")

                StatsSummaryCard(
                    rate: summary.rate,
                    bestStreak: summary.bestStreak,
                    periodTitle: provider.period.sectionTitle,
                    identifierPrefix: "stats"
                )

                habitList(summary.habits)
            }
            .padding(MCSpacing.lg)
        }
    }

    private func habitList(_ habits: [StatsHabitSummary]) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Per habit")
                .font(MCTypography.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(habits.enumerated()), id: \.element.id) { index, item in
                StatsHabitRow(
                    name: item.habit.name,
                    icon: item.habit.icon,
                    colorHex: item.habit.colorHex,
                    streak: item.streak,
                    rate: item.rate,
                    days: item.days,
                    identifierPrefix: "stats-habit-row-\(index)"
                )
                .onTapGesture { provider.goToHabitStats(item.habit) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(PreviewContainer.make())
}
